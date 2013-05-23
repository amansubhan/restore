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

module AgentSettingsTree
  class Object < ::TreeObject
    attr_reader :object_id
    def initialize(id, object, options)
      super(id, options)
      if object
        @object_id = object.id
        @selected = object.included?
      end
      @target_id = options[:target_id]      
      @target_class = options[:target_class]
      @target_options = options[:target_options]
      @partial_name = 'settings_browse_object'
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

  class Container < Object
    include TreeContainer
    
    attr_reader :error
    attr_reader :job_key
    attr_reader :session_id
    attr_accessor :loaded
    
    def initialize(id, object, options)
      super
      
      @error = nil
      @loaded = false
      @partial_name = 'settings_browse_container'
      @session_id = options[:session_id]
      
    end

    def agent_path
      '/'+path.split(/\//)[1..-1].join('/')
    end

    # for asynchronous operation
    def children
      load_children if expanded && @children.nil?
      @children
    end

    # for asynchronous load request
    def load_children
      @children = {}
      RAILS_DEFAULT_LOGGER.info "uhh: #{self.path}"
      
      @job_key = @target_class.new_worker(:list_objects, ['localhost', '7777', self.agent_path],
      { :oncomplete => "settings_browser_refresh_object('#{self.path}');", :session_id => self.session_id})
    end

    #def toggle_expanded
    #  super
    #  if expanded
    #    @children = nil
    #  else
    #    @loaded = false
    #  end
    #end

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
  
  class Agent < ::TreeObject
    include TreeContainer

    # all for async operation
    attr_reader :job_key
    attr_reader :session_id
    attr_accessor :loaded
    attr_accessor :error
    
    def initialize(target, options)
      super('settings_browser', options)

      #@loaded = false
      @partial_name = 'settings_browse_agent'
      @name = target.root_name      
      @target_id = target.id
      @target_class = target.class
      @target_hostname = target.hostname
      @target_port = target.port
      
      # for async operation
      @error = nil
      @loaded = false
      @partial_name = 'settings_browse_container'
      @session_id = options[:session_id]      
    end
    
    # for asynchronous operation
    def children
      load_children if expanded && @children.nil?
      @children
    end

    # for asynchronous load request
    def load_children
      @children = {}
      @job_key = @target_class.new_worker(:list_objects, [@target_hostname, @target_port, '/'],
        { :oncomplete => "settings_browser_refresh_object('#{self.path}');", :session_id => @session_id})
    end

    # evaluate this
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
      end
    end
        
    def kind
      # XXX probe from agent
      'Linux Agent'
    end
    
  end
  
end