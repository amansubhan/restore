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
  module Snapshot
    require_dependency 'restore/snapshot'
    
    class Agent < Base
      has_many :logs, :class_name => 'Restore::Module::Agent::ObjectLog', :foreign_key => 'snapshot_id', :dependent => :delete_all
      
      
      def size
        #logs.sum(:local_size, :conditions => "file_type != 'D' AND pruned=0") || 0
        logs.sum(:local_size) || 0
      end

      # XXX uhm, what?
      def calculate_local_size
        #logs.sum(:local_size, :conditions => "pruned=0") || 0
        logs.sum(:local_size) || 0
      end
      
      #def dav_resource_class
      #  module_require_dependency :filesystem, 'dav_resource/snapshot'
      #  Restore::Modules::Filesystem::DavResource::Snapshot
      #end
      
    end
    
  end
end
