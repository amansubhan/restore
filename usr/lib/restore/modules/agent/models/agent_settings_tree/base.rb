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
  class Base < ::TreeItem
    attr_accessor :error
    attr_reader :session_id
    attr_reader :target_id
    attr_reader :target_class
    attr_reader :target_options
    attr_reader :object_id
    
    def initialize(id, object, options)
      super(id, options)
      @error = nil
      if object
        @object_id = object.id
        @selected = object.included?
      end

      @session_id = options[:session_id]
      @target_id = options[:target_id]      
      @target_class = options[:target_class]
      @target_options = options[:target_options]
      @partial_name = 'settings_browse_base'
    end

    def <<(child)
      @children ||= {}
      @children[child.id] = child
      child.parent = self
      # this comment is why we override.
      # XXX make this the desired action on the base class.
      #child.selected = self.selected
    end

    def path
      if parent
        File.join(parent.path, CGI::escape(self.name))
      else
        "/"
      end
    end
  
    def kind
      self.class.to_s.split(/::/).last
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
      end
    end
    
  end
end
=end