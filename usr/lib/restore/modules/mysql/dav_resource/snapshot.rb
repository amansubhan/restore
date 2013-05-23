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
        module_require_dependency :mysql, 'dav_resource/database'
        
        require 'restore/dav_resource/snapshot'
        class Snapshot < Restore::DavResource::Snapshot

          def children
            snapshot.target.databases.map{|db|
              if (log = db.log_for_snapshot(snapshot)) && log.snapshot
                Restore::Modules::Mysql::DavResource::Database.new(self, snapshot, log, db)
              end
            }
          end

          def get_resource_for_path(path)
            if (database = snapshot.target.databases.find_by_name(path[0])) &&
              (log = database.log_for_snapshot(snapshot)) && log.snapshot
              
              dr = Restore::Modules::Mysql::DavResource::Database.new(self, snapshot, log, database)
              if path[1..-1].empty?
                return dr
              else
                return dr.get_resource_for_path(path[1..-1])
              end
              
            end
          end
        end
      end
    end
  end
end