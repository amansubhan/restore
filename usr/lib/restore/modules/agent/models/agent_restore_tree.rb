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

module AgentRestoreTree

  class Object < ::TreeObject
    def initialize(object, snapshot, log)
      # XXX can't hold these activerecord objects!

      @object, @snapshot, @log = object, snapshot, log
      super(@object.id.to_s,
      :name => @object.name,
      :partial_name => 'restore_browse_object'
      )
    end

    def set_snapshot(snapshot)
      @snapshot = snapshot
      @log = @object.log_for_snapshot(@snapshot)
    end

    def size
      @log.remote_size
    end

    def btime
      @log.btime
    end

    def error
      @log.error
    end
    
    def set_snapshot(snapshot)
      # XXX no storage of these AR objects
      @snapshot = snapshot
      @log = @object.log_for_snapshot(@snapshot)      
    end
    
  end
  
  class Container < Object
    include TreeContainer

    def initialize(object, snapshot, log)
      # XXX can't hold these activerecord objects!
      @object, @snapshot, @log = object, snapshot, log
      super(@object, snapshot, log)
      @expanded = false
    end

    def add_item_from_object(object, log)
      if log.container?
        self << Container.new(object, @snapshot, log)
      else
        self << Object.new(object, @snapshot, log)
      end
    end

    def load_children    
      @children ||= {}
      @object.children(true).each do |o|
        if (l = o.log_for_snapshot(@snapshot)) && l.event != 'D'
          if c = @children[o.id.to_s]
            #if (c.file_type == 'D' && l.file_type != 'D') ||
            #  (c.file_type != 'D' && l.file_type == 'D')
            #  @children.delete(file.id.to_s)          
            #  add_item_from_file(file, l)
            #end
            c.set_snapshot(@snapshot)
          else  
            add_item_from_object(o, l)
          end
        else
          @children.delete(o.id.to_s)          
        end
      end
    end

    def set_snapshot(snapshot)
      super
      load_children if expanded?
    end
  end

  class Agent < ::TreeObject
    include TreeContainer

    def initialize(target, snapshot)
      super('restore_browser', {})

      @partial_name = 'restore_browse_agent'
      @name = target.root_name      
      @target_id = target.id
      @target = target
      @snapshot = snapshot
      @expanded = true
    end
    
    def target
      @target
      #Restore::Target::Agent.find(@target_id)
    end
    
    def add_item_from_object(object, log)
      if log.container?
        self << Container.new(object, @snapshot, log)
      else
        self << Object.new(object, @snapshot, log)
      end
    end
    
    def load_children
      @children ||= {}
      target.root_objects(true).each do |obj|
        if (l = obj.log_for_snapshot(@snapshot)) && l.event != 'D'
          if c = @children[obj.id.to_s]
            #if (c.file_type == 'D' && l.file_type != 'D') ||
            #  (c.file_type != 'D' && l.file_type == 'D')
            #  @children.delete(file.id.to_s)          
            #  add_item_from_file(file, l)
            #end
            c.set_snapshot(@snapshot)
          else
            add_item_from_object(obj, l)
          end
        else
          @children.delete(obj.id.to_s)          
        end
      end
    end

    def set_snapshot(snapshot)
      # XXX no storage of these AR objects
      @snapshot = snapshot
      #if expanded
      #  load_children
      #end
    end
    
    
    
  end
  
end