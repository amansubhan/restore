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

module MysqlWizardTree
  class Database < ::TreeItem
    def initialize(*args)
      super
      @partial_name = 'browse_database'      
    end
    def <<(child)
      super
      child.selected = self.selected
    end

    def load_children
      @children = {}
      dbh = parent.dbh
      dbh.query("SELECT
      `TABLE_NAME`,
      `TABLE_TYPE`,
      `ENGINE`,
      `TABLE_ROWS`,
      `DATA_LENGTH`,
      `INDEX_LENGTH`,
      `CREATE_TIME`,
      `UPDATE_TIME`,
      `TABLE_COLLATION`
      FROM `information_schema`.`TABLES`
      WHERE `TABLE_SCHEMA`='#{self.name}'").each do |row|
        klass = row[1] == 'VIEW' ? View : Table
        self << klass.new(
          row[0],
          :extra => {
            :type => row[1],
            :engine => row[2],
            :rows => row[3],
            :size => row[4],
            :index_size => row[5],
            :created => row[6],
            :updated => row[7],
            :collation => row[8]
          })
      end

      dbh.query("SELECT
      `ROUTINE_NAME`,
      `ROUTINE_TYPE`
      FROM `information_schema`.`ROUTINES`
      WHERE `ROUTINE_SCHEMA`='#{self.name}'").each do |row|
        self << Routine.new(
          row[0],
          :extra => { :type => row[1] }
        )
      end
    end
  end
end