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
  module Modules
    module Mysql
      module_require_dependency :mysql, 'log'
      
      class DatabaseLog < Log
        
        belongs_to :database, :foreign_key => 'database_id'
                
        def browse_size
          connection.select_value("SELECT sum(local_size) FROM mysql_logs where database_id='#{database.id}' and (snapshot_id <= #{snapshot_id}) and type='TableLog' order by snapshot_id desc limit 1") 
          
        end
        
        def prune
          removed = local_size rescue 0
          #if storage
            storage.unlink
            update_attributes(:pruned => true, :local_size => 0)
          #end
          snapshot.update_attributes(:local_size => (snapshot.local_size - removed))
        end
        
        def storage
          @sd_file_handle ||= snapshot.storage.get_file_handle(database.local_path)
        end
        
      end
    end
  end
end