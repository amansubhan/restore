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
  class Agent < ::TreeItem
    # this class isn't actually backed by an object on the agent,
    # so we must handle it differently
    
    attr_reader :job_key
    attr_accessor :loaded
    attr_accessor :error
    
        
    def initialize(target, options)
      super('settings_browser', options)
      @error = nil
      @name = target.root_name
      @target_id = target.id
      @target_class = target.class
      @target_hostname = target.hostname      
      @target_port = target.port
      @session_id = options[:session_id]
      @partial_name = 'settings_browse_agent'
    end
    
    def <<(child)
      @children ||= {}
      @children[child.id] = child
      child.parent = self
      # this comment is why we override.
      # XXX make this the desired action on the base class.
      #child.selected = self.selected
    end
    
    def children
      load_children if expanded && @children.nil?
      @children
    end
    
    def load_children
      @children = {}
      @job_key = @target_class.new_worker(:list_objects, [@target_hostname, @target_port, '/'],
        { :oncomplete => "refresh_directory('#{self.full_id}');", :session_id => @session_id})
    end

    def toggle_expanded
      super
      if expanded
        @children = nil
      else
        @loaded = false
      end
    end
    
    def path
      '/'
    end
    
  end
end

=end