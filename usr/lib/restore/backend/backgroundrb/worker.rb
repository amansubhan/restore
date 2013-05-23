# Copyright (c) 2006, 2007 Ruffdogs Software, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

require 'drb'
require 'logger'
require 'monitor'
require 'backgroundrb/middleman'

module BackgrounDRb
  module Worker

    class Base
      include DRbUndumped

      attr_reader :jobkey
      attr_accessor :results
      attr_accessor :initial_do_work
      
      def initialize(args=nil, jobkey=nil)
        @jobkey   = jobkey
        @args     = args
        @results  = {}

        case jobkey
        when :restore_logger, :restore_results
        else
          @results.extend(BackgrounDRb::Results)
          @results.init(jobkey)
        end
        @initial_do_work = true
      end

      def logger
        unless self.class == 'BackgrounDRb::Worker::WorkerLogger'
          @logger_stub ||= MiddleMan.instance.worker(:restore_logger).get_logger
        end
      end

      # Background a method call in a worker
      def work_thread(opts)

        args = opts[:args]
        case 
        when args.is_a?(Symbol)
          case opts[:args].id2name
          when /\A@/
            send_args = self.instance_variable_get(opts[:args].id2name)
          else
            # TODO: not sure what this would be used for
            send_args = args
          end
          send = lambda do
            self.send(opts[:method], send_args)
          end
        when args.nil?
          send = lambda do
            self.send(opts[:method])
          end
        else
          send = lambda do
            self.send(opts[:method], args)
          end
        end

        Thread.new do
          begin
            send.call
          rescue StandardError => e
            logger.error(@jobkey) { "#{ e.message } - (#{ e.class })" } 
            (e.backtrace or []).each do |line|
              logger.error(@jobkey) { "#{line}" }
            end
            self.delete
          end
        end

      end

      def delete
        exit!
      end

    end




  end

end  

# RailsBase will be loaded in BackgrounDRb::Server#setup
