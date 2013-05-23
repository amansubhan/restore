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
  module_require_dependency :agent, 'object/base'
  module_require_dependency :agent, 'snapshot'

  module Target
    class Agent < Restore::Target::Base
      has_many :objects,
        :class_name => 'Restore::Module::Agent::Object::Base',
        :foreign_key => 'target_id',
        :dependent => :delete_all
      has_many :root_objects,
        :conditions => 'parent_id is null',
        :class_name => 'Restore::Module::Agent::Object::Base',
        :foreign_key => 'target_id'

      #has_many :logs,
      #  :class_name => 'Restore::Module::Agent::ObjectLog',
      #  :foreign_key => 'target_id'
        
      #def root_objects(refresh=false)
      #  objects.find_all_by_parent_id(nil)
      #end

      def find_root_object_by_name(name)
        objects.find_by_name_and_parent_id(name, nil)
      end

      
      def self.snapshot_class
        module_require_dependency :agent, 'snapshot'
        Restore::Snapshot::Agent
      end
      
      def self.browser_class
        ('Restore::Browser::'+self.to_s.split(/::/)[-1])
      end
      
      def root_name
        "restoreagent://#{hostname}:#{port}"
      end
      
      def port
        self.extra ||= {}
        self.extra[:port] ||= 7777
      end
      
      def port=(val)
        self.extra ||= {}
        self.extra[:port] = val.to_i
      end
      
      def find_object_by_path(path)
        path_array = path.split('/')[1..-1]
        root_name = path_array.shift
        if obj = find_root_object_by_name(CGI::unescape(root_name))

          if path_array.empty?
            return obj
          elsif child = obj.find_child_by_path(path_array.join('/'))
            return child
          end
        end
        return nil
      end
    
    end
  end
end
