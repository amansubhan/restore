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

module FilesystemSettingsTree
  require_dependency 'filesystem_settings_tree/file'
  class Directory < File
    attr_accessor :loaded
    attr_reader :job_key
    
    def initialize(id, options)
      super
      @loaded = false
    end

    def <<(child)
      @children ||= {}
      child.id = @children.keys.size.to_s
      @children[child.id] = child
      child.parent = self
    end
    
    def load_children
      @children ||= {}
      unless self.loaded
        @job_key = @target_class.new_worker(:list_directory, [self.path, self.target_options],
          { :oncomplete => "refresh_directory('#{self.full_id}');", :session_id => self.session_id})
      end
    end
    
    def selected=(val)
      @selected = val
      if @file_id && (file = Restore::Modules::Filesystem::File.find(@file_id))
        if file.parent
          file.included = (val == file.parent.included) ? nil : val
        else
          file.included = val          
        end
        file.save
        
        # if this directory is loaded, the controller will take care of
        # calling select= on the child items.
        if !self.loaded
          # gotta update all children too
          ids = file.all_children_ids.join(',')
          file.connection.update("update filesystem_files set included=NULL where id in(#{ids}) AND included IS NOT NULL") unless ids.empty?
        end
      end
    end
    
  end
end