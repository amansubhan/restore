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
        require 'restore/dav_resource/snapshot'
        module_require_dependency :filesystem, 'dav_resource/file'

        class Snapshot < Restore::DavResource::Snapshot

          def children
            snapshot.target.root_directory.children.map{|f|
              path = f.path[1..-1]
              if (log = f.log_for_snapshot(snapshot)) && log.snapshot
                Restore::Modules::Filesystem::DavResource::File.new(self, snapshot, log, f)
              end
            }
          end

          def get_resource_for_path(path)
            if (file = snapshot.target.files.find_by_path('/'+::File.join(path))) &&
              (log = file.log_for_snapshot(snapshot)) && log.snapshot
              # XXX need to supply all path components?
              return Restore::Modules::Filesystem::DavResource::File.new(self, snapshot, log, file)
            else
              raise WebDavErrors::ForbiddenError
            end
          end
        end
      end
    end
  end
end