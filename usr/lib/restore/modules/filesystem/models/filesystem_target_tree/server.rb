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

module FilesystemTargetTree
  class Server < Directory

    def initialize(target, snapshot)
      super(target.root_directory, snapshot, nil)
      @id = 'server'
      @partial_name = 'browse_server'
      @expanded = true
      @name = target.root_name
    end

  end
end