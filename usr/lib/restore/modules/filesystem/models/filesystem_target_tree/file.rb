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
  class File < ::TreeItem

    def initialize(file, snapshot, log)
      @file, @snapshot, @log = file, snapshot, log
      super(@file.id.to_s,
        :name => @file.filename,
        :partial_name => 'browse_file',
        :expanded => false)
    end

    def set_snapshot(snapshot)
      @snapshot = snapshot
      @log = @file.log_for_snapshot(@snapshot)
    end

    def file_type
      @log.file_type
    end

    def size
      @log.remote_size
    end

    def mtime
      @log.mtime
    end
    
    def btime
      @log.btime
    end
    
    def error
      @log.error
    end


  end
end