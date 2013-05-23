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

module MysqlTargetTree
  class Table < ::TreeItem

    def initialize(table, snapshot, log)
      @table, @snapshot, @log = table, snapshot, log
      super(@table.id,
        :name => @table.name,
        :partial_name => 'browse_table',
        :expanded => false)
    end
    
    def set_snapshot(snapshot)
      @snapshot = snapshot
    end
    
    def size
      @log.local_size
    end

    def collation
      
    end
    
    def engine
      @log.table_engine
    end
      
    def backup_time
      @log.btime
    end

  end
end