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
=begin
module AgentSettingsTree
  class Container < Base
    attr_reader :job_key
    attr_accessor :loaded
        
    def initialize(id, object, options)
      super
      
      @loaded = false
      @partial_name = 'settings_browse_container'
      
    end
    
    def children
      load_children if expanded && @children.nil?
      @children
    end
    
    def load_children
      @children = {}
      @job_key = @target_class.new_worker(:list_objects, ['localhost', '7777', self.path],
        { :oncomplete => "refresh_directory('#{self.full_id}');", :session_id => self.session_id})
    end

    def toggle_expanded
      super
      if expanded
        @children = nil
      else
        @loaded = false
      end
    end
    
    def selected=(val)
      @selected = val
      if @object_id && (obj = Restore::Module::Agent::Object::Base.find(@object_id))
        if obj.parent
          obj.included = (val == obj.parent.included) ? nil : val
        else
          obj.included = val          
        end
        obj.save
        
        # if this directory is loaded, the controller will take care of
        # calling select= on the child items.
        if !self.loaded
          # gotta update all children too
          ids = obj.all_children_ids.join(',')
          obj.connection.update("update agent_objects set included=NULL where id in(#{ids}) AND included IS NOT NULL") unless ids.empty?
        end
      end
    end
    

  end
end
=end