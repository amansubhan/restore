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
  module_require_dependency :filesystem, 'file'
  module_require_dependency :filesystem, 'log'
  module_require_dependency :filesystem, 'snapshot'

  module Target
    class Filesystem < Restore::Target::Base
      has_many :files, :class_name => 'Restore::Modules::Filesystem::File', :foreign_key => 'target_id', :dependent => :delete_all
      has_many :logs, :class_name => 'Restore::Modules::Filesystem::Log', :foreign_key => 'target_id', :dependent => :delete_all

      self.abstract_class = true

      def root_directory()
        files.find_by_parent_id(nil)
      end
      
      def self.snapshot_class
        module_require_dependency :filesystem, 'snapshot'
        Restore::Snapshot::Filesystem
      end
      
      def self.browser_class
        ('Restore::Browser::'+self.to_s.split(/::/)[-1])
      end
      
      def root_name
        'root'
      end
    
    end
  end
end
