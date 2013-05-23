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

module MysqlSettingsTree
  class Table < ::TreeItem
    def initialize(table, extra)
      super(table.name, extra)
      @partial_name = 'settings_browse_table'      
      @selected = table.included?
      @table_id = table.id
    end
    
    def selected=(val)
      @selected = val
      if @table_id && (table = Restore::Modules::Mysql::Table.find(@table_id))
        table.included = (val == table.database.included) ? nil : val
        table.save
      end
    end
    
  end
end