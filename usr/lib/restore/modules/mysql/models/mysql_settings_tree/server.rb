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
  class Server < ::TreeItem
    attr_reader :error
    attr_reader :target_id
    
    def initialize(target)
      @target_id = target
      @target = target
      @hostname = target.hostname
      @port = target.port
      @username = target.username
      @password = target.password
      super('settings_browser_root',
        :name => "mysql://#{@username}@#{@hostname}:#{@port}/",
        :partial_name => 'settings_browse_server',
        :expanded => true,
        :selected => target.included?)
      @error = nil
      load_children

    end

    def <<(child)
      @children ||= {}
      @children[child.id] = child
      child.parent = self
    end

    def dbh
       Mysql.real_connect(@hostname, @username, @password, nil, @port)        
    end

    def target
      Restore::Target::Mysql.find(@target_id)
    end

    def load_children
      @children = {}
      # create database tables
      
      begin
        d = self.dbh
        d.query("SHOW DATABASES").each do |row|
          dbname = row[0]
          size = d.query("SELECT
            sum(`DATA_LENGTH`)
            FROM `information_schema`.`TABLES`
            WHERE `TABLE_SCHEMA`='#{dbname}'").fetch_row[0] || 0
          unless db = target.databases.find_by_name(dbname)
            db = target.databases.create(:name => dbname)
          end
          self << Database.new(db, :extra => {:size => size})
        end
      rescue => e
        @error = e.to_s
      end
    end
    
    def selected=(val)
      @selected = val
      t = self.target
      t.included = val
      t.save
      if !self.children
        # gotta update all children too
        ids = t.database_ids.join(',')
        t.connection.update("update mysql_databases set included=NULL where id in(#{ids}) AND included IS NOT NULL") unless ids.empty?
      end
    end
    

  end
end