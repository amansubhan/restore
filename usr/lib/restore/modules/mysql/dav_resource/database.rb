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
      module DavResource
        module_require_dependency :mysql, 'dav_resource/table'
        
        class Database < ::DavResource::Base

          attr_reader :snapshot
          attr_reader :database
          attr_reader :log

          def initialize(parent, s, log, db)
            super(parent)
            @snapshot = s
            @database = db
            @log = log
          end

          def collection?
            true
          end

          def children
            database.tables.map {|t|
              if (log = t.log_for_snapshot(snapshot)) && log.snapshot
                  Restore::Modules::Mysql::DavResource::Table.new(self, snapshot, log, t)
              end
            }
          end

          def getcontenttype
            "httpd/unix-directory"
          end

          def properties
            [:displayname, :creationdate, :getcontenttype, :getcontentlength]
          end

          def displayname
            database.name
          end

          def creationdate
            Date.today
          end

          def getcontentlength 
            log.local_size
          end

          def getlastmodified
            log.mtime
          end
          
          def get_resource_for_path(path)
            if (table = database.tables.find_by_name(path[0].gsub(/\.sql/, ''))) &&
              (log = table.log_for_snapshot(snapshot)) && log.snapshot
              return Restore::Modules::Mysql::DavResource::Table.new(self, snapshot, log, table)
            end
          end
          

        end
      end
    end
  end
end