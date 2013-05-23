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
  class Server < ::TreeItem
    attr_reader :error
    
    def initialize(hostname, port, username, password)
      @hostname, @port, @username, @password = hostname, port, username, password
      super('server',
        :name => "mysql://#{@username}@#{@hostname}:#{@port}/",
        :partial_name => 'browse_server',
        :expanded => true,
        :selected => true)
      @error = nil
      load_children
      @partial_name = 'browse_server'
    end

    def <<(child)
      super
      child.selected = self.selected
    end

    def dbh
       Mysql.real_connect(@hostname, @username, @password, nil, @port)        
    end

    def load_children
      @children = {}
      # create database tables
      begin
        d = self.dbh
        d.query("SHOW DATABASES").each do |row|
          dbname = row[0]
          r2 = []
          r2 = d.query("SELECT
            max(`UPDATE_TIME`),
            count(`TABLE_NAME`),
            sum(`TABLE_ROWS`),
            sum(`DATA_LENGTH`),
            sum(`INDEX_LENGTH`)
            FROM `information_schema`.`TABLES`
            WHERE `TABLE_SCHEMA`='#{dbname}'").fetch_row
            
          self << Database.new(
            dbname,
            :extra => {
              :updated => r2[0],
              :tables => r2[1],
              :rows => r2[2],
              :size => r2[3],
              :index_size => r2[4],
          })  
        end
      rescue => e
        @error = e.to_s
      end
    end

  end
end