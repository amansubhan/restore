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
        class Table < ::DavResource::Base
          attr_reader :snapshot
          attr_reader :table
          attr_reader :log

          def initialize(parent, s, log, t)
            super(parent)
            @snapshot = s
            @table = t
            @log = log
            
          end

          def collection?
            false
          end

          def getcontenttype
            "httpd/unix-directory"
          end

          def properties
            [:displayname, :creationdate, :getcontenttype, :getcontentlength]
          end

          def displayname
            table.name+'.sql'
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
          
          
          def data            
            io = log.storage.open("r")
          end

        end
      end
    end
  end
end