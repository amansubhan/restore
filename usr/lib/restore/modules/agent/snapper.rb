# Copyright (c) 2006, 2007 Ruffdogs Software, Inc.
# Authors: Adam Lebsack <adam@holonyx.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

module Restore
  module Snapper
    require 'restore/snapper'
    
    class Agent < Restore::Snapper::Base
      
      class ObjectProxy
        attr_reader :logger
        
        @@cache = []
        # special proxy to master-side objects
        include DRbUndumped
        def initialize(object, snapshot_id, logger)
          @object, @snapshot_id, @logger = object, snapshot_id, logger
          @snapshot = @object.target.snapshots.find(snapshot_id)
        end
        
        def find_or_create_child(name)
          if c = @object.find_or_create_child(name)
            op = ObjectProxy.new(c, @snapshot_id, @logger)
            @@cache << op
            return op
          end
        end

        def update_data(event, container, attrs, io)
          begin
            logger.info "#{event} #{@object.path}"
            # accept and store what io has to say.  then update the log

            # gimpy way of making sure the parent has a log.
            # XXX perhaps put into post processing/cleanup?
            @object.find_or_create_parent_log(@snapshot, event)
            
            unless log = @object.log_for_snapshot(@snapshot)
              log = @object.logs.create(
                :snapshot_id => @snapshot_id,
                :event => event,
                :container => container)
            end
            
            local_size = 0
            if io
              logger.info "we have IO"
              log.storage.open('w') do |local|
                while data = io.read(64.kilobytes)
                  local.write data
                end
              end
              local_size = log.storage.size
            end

            log.update_attributes(
              :btime => Time.now,
              :local_size => local_size)
          end
        rescue => e
          logger.info e.to_s+e.backtrace.join("\n")
        end
      end # class ObjectProxy

      def prepare
        super
        # compile a list of items to backup.
        objs = target.objects.find(:all, :conditions => "included is not null")
        @object_config = {}
        objs.each do |o|
          @object_config[o.path] = {:included => o.included }
        end

        require 'xmlrpc/client'
        @rpc_server = XMLRPC::Client.new2("http://#{target.hostname}:#{target.port}/")
        
        @data_server = Net::HTTP::new(target.hostname,target.port)
        
        
        begin
          ret = @rpc_server.call("agent.new_snapshot", snapshot.id, @object_config)
        rescue XMLRPC::FaultException => e
          puts "XMLRPC Fault: #{e.message}"
        end
        #puts ret.inspect
      end

      def execute
        super
        start = Time.now
        size = 0
        loop do
          begin
            ret = @rpc_server.call("snapshot.#{snapshot.id}.execute")
          rescue => e
            puts "XMLRPC Fault: #{e.message} #{e.backtrace.join("\n")}"
            break
          end
          break if ret == 'DONE'
          if path = ret['path']
            logger.info "#{ret['event']} #{ret['path']}"
            logger.info "#{ret['data_href']}"
            
            # get the data stream with our other connection
            get_file(ret['data_href']) if ret['data_href']
            
          else
            logger.info "unknown data: #{ret}"
          end
        end
        
        #time = Time.now - start
        #puts "#{size} bytes in #{time} seconds: rate: #{size/time}"
        
      end

      def cleanup
        super
        #@rpc_server.close
      end

      protected
      def prepare_object(object)
        
      end
      
      
      def get_file(path)
        start = Time.now
        size = 0
        @data_server.get2(path) do |resp|
          resp.read_body do |segment|
            size += segment.length
            puts "segment size: #{segment.size}"
          end
        end
        time = Time.now - start
        puts "#{size} bytes in #{time} seconds: rate: #{(size/time)/1024}kb/s"
        
        
      end

    end
  end
end
