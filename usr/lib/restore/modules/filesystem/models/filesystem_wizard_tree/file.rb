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
  class File < ::TreeItem
    attr_accessor :error
    attr_reader :size
    attr_reader :mtime
    attr_reader :path
    attr_reader :session_id
    attr_reader :target_options
    attr_reader :file_type
    attr_accessor :id
    
    def initialize(id, options)
      super
      @error = options[:error]
      @path = options[:path]
      @session_id = options[:session_id]
      @target_class = options[:target_class]
      @target_options = options[:target_options]
      @size = options[:size]
      @mtime = options[:mtime]
      @file_type = options[:file_type]
      
    end


  end
end