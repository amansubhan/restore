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
    module_require_dependency :mysql, 'log'
    module_require_dependency :mysql, 'database_log'
    module_require_dependency :mysql, 'table_log'
    require_dependency 'restore/snapshot'
    
    class Mysql < Base
      has_many :database_logs, :class_name => 'Restore::Modules::Mysql::DatabaseLog',
        :foreign_key => 'snapshot_id'

      has_many :table_logs, :class_name => 'Restore::Modules::Mysql::TableLog',
        :foreign_key => 'snapshot_id'
      
      has_many :logs, :class_name => 'Restore::Modules::Mysql::Log',
        :foreign_key => 'snapshot_id', :dependent => :delete_all
            
      def calculate_local_size
        logs.sum(:local_size) || 0
      end
      
      def dav_resource_class
        module_require_dependency :mysql, 'dav_resource/snapshot'
        Restore::Modules::Mysql::DavResource::Snapshot
      end
      
      
    end
  end
end
