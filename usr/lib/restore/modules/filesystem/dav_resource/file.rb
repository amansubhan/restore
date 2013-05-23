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
    module Filesystem
      module DavResource
        class File < ::DavResource::Base
          attr_reader :snapshot
          attr_reader :file
          attr_reader :log

          def initialize(parent, s, log, f)
            super(parent)
            @snapshot = s
            @file = f
            @log = log
          end

          def collection?
            (log.file_type == 'D')
          end

          def children
            if log.file_type == 'D'
              file.children.map {|c|
                if (log = c.log_for_snapshot(snapshot)) && log.snapshot
                  File.new(self, snapshot, log, c)
                end
              }
            else
              []
            end
          end

          def getcontenttype
            if (log.file_type == 'D')
              "httpd/unix-directory"
            else
              mimetype = MIME::Types.type_for(displayname).first.to_s
              mimetype = "application/octet-stream" if mimetype.blank?
              mimetype
            end
          end

          def properties
            [:displayname, :creationdate, :getcontenttype, :getcontentlength]
          end

          def displayname
            file.filename
          end

          def creationdate
            Date.today
          end

          def getcontentlength 
            log.local_size
          end

          def data
            log.storage.open("r")
          end

          def getlastmodified
            log.mtime
          end

        end
      end
    end
  end
end