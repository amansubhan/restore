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
  class Database < ::TreeItem
    
    attr_reader :database
    attr_reader :log
    
    def initialize(database, snapshot, log)
      @database, @snapshot, @log = database, snapshot, log
      super(@database.name,
        :partial_name => 'browse_database',
        :expanded => false)
    end
    
    def load_children
      @children ||= {}
      @database.tables.each do |table|
        if (l = table.log_for_snapshot(@snapshot)) && l.event != 'D'
          if c = @children[table.id.to_s]
            c.set_snapshot(@snapshot)
          else  
            self << Table.new(table, @snapshot, l)
          end
        else
          @children.delete(table.id.to_s)
        end
      end
    end
    
    def set_snapshot(snapshot)
      @snapshot = snapshot
      if expanded
        load_children
      end
    end
    
    def size
      @log.browse_size
      #@database.tables.inject(0) {|s,t|
      #  if (l = t.log_for_snapshot(@snapshot)) && l.event != 'D'
      #    s += l.local_size
      #  end
      #}
    end
    
    def collation
      
    end
    
    def num_tables
    end
    
    def num_rows
      
    end
    
    def backup_time
      @log.btime
    end
    
  end
end