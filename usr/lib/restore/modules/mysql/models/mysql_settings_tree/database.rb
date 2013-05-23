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
  class Database < ::TreeItem
    def initialize(database, extra)
      super(database.name, extra)
      @database_id = database.id
      @selected = database.included?
      @partial_name = 'settings_browse_database'
    end

    def <<(child)
      @children ||= {}
      @children[child.id] = child
      child.parent = self
    end

    def load_children
      @children = {}
      dbh = parent.dbh
      dbh.query("SELECT
      `TABLE_NAME`,
      `TABLE_TYPE`,
      `DATA_LENGTH`
      FROM `information_schema`.`TABLES`
      WHERE `TABLE_SCHEMA`='#{self.name}'").each do |row|
        type = row[1]
        klass = (type == 'VIEW') ? View : Table
        name = row[0]
        size = row[2]
        database = parent.target.databases.find(@database_id)  
        unless table = database.tables.find_by_name(name)
          table_klass = (type == 'VIEW') ? Restore::Modules::Mysql::View : Restore::Modules::Mysql::Table
          table = table_klass.create(:name => name, :database_id => @database_id, :target_id => parent.target_id)
        end
        self << klass.new(table, :extra => {:type => type, :size => size})
      end

      dbh.query("SELECT
      `ROUTINE_NAME`,
      `ROUTINE_TYPE`
      FROM `information_schema`.`ROUTINES`
      WHERE `ROUTINE_SCHEMA`='#{self.name}'").each do |row|
        name = row[0]
        type = row[1]
        unless routine = database.routine.find_by_name(name)
          routine = Restore::Modules::Mysql::Routine.create(:name => name, :database_id => @database_id, :target_id => parent.target_id)
        end
        self << Routine.new(routine, :extra => { :type => type })
      end
    end
    
    def selected=(val)
      @selected = val
      if database = parent.target.databases.find(@database_id)
        database.included = (val == database.target.included?) ? nil : val
        database.save
      
        # if this database is loaded, the controller will take care of
        # calling select= on the child items.
        if !self.children
          # gotta update all children too
          ids = database.table_ids.join(',')
          database.connection.update("update mysql_tables set included=NULL where id in(#{ids}) AND included IS NOT NULL") unless ids.empty?
        end
      end
    end
    
  end
end