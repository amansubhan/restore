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
  class Directory < ::TreeItem

    def initialize(dir, snapshot, log)
      @directory, @snapshot, @log = dir, snapshot, log
      super(@directory.id.to_s,
        :name => @directory.filename,
        :partial_name => 'browse_directory',
        :expanded => false)
    end

    def add_item_from_file(file, log)
      if log.file_type == 'D'
        self << Directory.new(file, @snapshot, log)
      else
        self << File.new(file, @snapshot, log)
      end
    end

    def load_children    
      
      @children ||= {}
      @directory.children(true).each do |file|
        if (l = file.log_for_snapshot(@snapshot)) && l.event != 'D'
          if c = @children[file.id.to_s]
            if (c.file_type == 'D' && l.file_type != 'D') ||
              (c.file_type != 'D' && l.file_type == 'D')
              @children.delete(file.id.to_s)          
              add_item_from_file(file, l)
            end
            c.set_snapshot(@snapshot)
          else  
            add_item_from_file(file, l)
          end
        else
          @children.delete(file.id.to_s)          
        end
      end
    end

    def set_snapshot(snapshot)
      @snapshot = snapshot
      @log = @directory.log_for_snapshot(@snapshot)
      if expanded
        load_children
      end
    end

    def file_type
      @log.file_type
    end

    def size
      0
      #@log.remote_size
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