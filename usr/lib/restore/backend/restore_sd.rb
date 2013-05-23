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

module RestoreSD
  class Server
    def initialize
    end

    def get_target_handle(target_id)
      TargetHandle.new(target_id)
    end
  end
  
  class TargetHandle
    include DRbUndumped
    def initialize(target_id)
      @target_id = target_id
    end

    def get_snapshot_handle(snapshot_id)
      SnapshotHandle.new(self, snapshot_id)
    end
    
    def base_path
      File.join(Restore::Config.backups, @target_id.to_s)
    end
    
    def destroy
      FileUtils.rm_rf(base_path)
      true
    end
    
    
  end
  
  class SnapshotHandle
    include DRbUndumped
    
    attr_accessor :snapshot_id
    
    def initialize(target_handle, snapshot_id)
      @target_handle, @snapshot_id = target_handle, snapshot_id
      mkdir_p('/')
    end
    
    def base_path
      File.join(@target_handle.base_path, @snapshot_id.to_s)
    end
    
    def sizeof(path)
      st = File.stat(File.join(base_path, path))
      st.blocks * 512
    end
    
    def mkdir_p(path)
      FileUtils::mkdir_p(File.join(base_path, path))
    end
    
    def get_file_handle(path)
      FileHandle.new(self, path)
    end
    
    def destroy
      FileUtils.rm_rf(base_path)
      true
    end
    
    def unlink(path)
      fullpath = File.join(base_path, path)
      if File.directory?(fullpath)
        Dir.unlink(fullpath)
      else
        File.unlink(fullpath)
      end
    end
    
  end
  
  class FileHandle
    include DRbUndumped
    attr_accessor :snapshot_handle
    
    def initialize(snapshot_handle, path)
      @snapshot_handle, @path = snapshot_handle, path
    end
    
    def path
      File.join(@snapshot_handle.base_path, @path)
    end
    
    def open(mode, &block)
      if block_given?
        File.open(path, mode) do |f|
          yield f
        end
      else
        File.new(path, mode)
      end
    end
    
    def size
      File.size(path) rescue 0
    end
    
    def unlink
      if File.directory?(path)
        Dir.unlink(path)
      else
        File.unlink(path)
      end
    end
    
    def mkdir
      FileUtils::mkdir_p(path)
    end
  end
end
