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
      
      class TableLog < Log
        
        belongs_to :table
        
        def prune
          removed = local_size rescue 0
          if storage
            storage.unlink
            update_attributes(:pruned => true, :local_size => 0)
            # is the parent dir empty?  if so, delete it, mark its new size
            #if Dir.entries(::File.dirname(local_path)).size == 2 # ['..', '.']
            #  ::Dir.unlink(::File.dirname(local_path))
            #  if table.database && (dlog = table.database.log_for_snapshot(snapshot))
            #    removed += dlog.local_size rescue 0
            #    dlog.update_attributes(:local_size => 0)
            #  end
            #end
          end          
          snapshot.update_attributes(:local_size => (snapshot.local_size - removed))
        end
        
        def storage
          @sd_file_handle ||= snapshot.storage.get_file_handle(table.local_path)
        end
                
      end
    end
  end
end