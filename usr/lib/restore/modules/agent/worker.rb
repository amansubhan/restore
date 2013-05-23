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

module Restore::Worker
  class Agent
    cattr_accessor :logger
    class << self
      def list_objects(hostname, port, path)
        require 'xmlrpc/client'
        server = XMLRPC::Client.new2("http://#{hostname}:#{port}/")
        children = server.call("agent.list_objects", path)
        
        children.collect!{|c| 
          nc = {}
          c.each_pair do |k,v|
            nc[k.to_sym] = v
          end
          nc
        }
        return {:children => children, :loaded => true}
      end

=begin
  DRb stuff
      def list_objects_old(hostname, port, path)
        require 'drb'
        if false
          require 'drb/drbfire'
        
          DRb.start_service("drbfire://#{hostname}:#{port}", nil, DRbFire::ROLE => DRbFire::CLIENT)
          ro = DRbObject.new(nil, "drbfire://#{hostname}:#{port}")
        else
          ro = DRbObject.new(nil, "druby://#{hostname}:#{port}")
        end
        children = ro.list_objects(path)
      
        return {:children => children, :loaded => true}
      end
=end
    end
  end
end
