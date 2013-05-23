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

module FilesystemWizardTree
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
        @job_key = @target_class.new_worker(:list_directory, [self.path, self.target_options], { :oncomplete => "refresh_directory('#{self.full_id}');", :session_id => self.session_id})
      end
    end

  end
end