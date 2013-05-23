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

module Restore::Module::Agent::Object
  
  class Base < ActiveRecord::Base
    module_require_dependency :agent, 'object_log'
    
    
    set_table_name 'agent_objects'
    belongs_to :target, :class_name => 'Restore::Target::Agent', :foreign_key => 'target_id'
    has_many :logs, :class_name => 'Restore::Module::Agent::ObjectLog', :foreign_key => 'object_id', :dependent => :delete_all

    acts_as_tree :scope => 'target_id', :order => 'name'

    #def before_create
    #  self.target_id = target.id if target
    #  self.parent_id = parent.id if parent
    #end

    def path
      if parent
        [parent.path, CGI::escape(name)].join('/')
      else
        '/'+CGI::escape(name)
      end
    end
    
    def find_child_by_path(path)
      path_array = path.split('/')
      child_name = path_array.shift
      if obj = children.find_by_name(CGI::unescape(child_name))
        if path_array.empty?
          return obj
        elsif child = obj.find_child_by_path(path_array.join('/'))
          return child
        end
      end
      return nil
    end
    
    def find_or_create_child(name)
      unless c = children.find_by_name(name)
        c = children.create(:name => name, :target_id => target_id)
      end
      c
    end
    
    def find_or_create_parent_log(snapshot, event)
      if parent
        unless l = parent.logs.find_by_snapshot_id(snapshot.id)
          l = parent.logs.create(:snapshot_id => snapshot.id, :event => event, :container => true)
        end
        return l
      end
      nil
    end

    def log_for_snapshot(snapshot)
      logs.find(:first,
        :conditions => "(snapshot_id <= #{snapshot.id} OR snapshot_id IS NULL)",
        :order => 'snapshot_id desc')
    end

    # is this object or any of its
    # children or subchildren included?
    def deep_included?
      # we're included, so yes
      return true if included?
      children.each do |c|
        #if any children are deep included, we are deep included
        return true if c.deep_included?
      end
      return false
    end

    # returns an array of all child and subchild objects, flattened
    def all_children
      children + children.collect {|f|
        f.all_children
      }.flatten.compact
    end

    # returns an array of the children ids, flattened        
    def children_ids
      children.collect {|f|
        f.id
      }.flatten.compact
    end

    # returns an array of all child and subchild ids, flattened
    def all_children_ids
      children.collect {|f|
        [f.id, f.all_children_ids]
      }.flatten.compact
    end

    # returns the level in the tree, 0 being the top
    def nesting
      if parent.nil?
        0
      else
        parent.nesting + 1
      end
    end

    # an array of the parents, immediate parent last
    def parents
      if parent.nil?
        []
      else
        parent.parents + [parent]
      end
    end

    # reads the :included attribute.  if null, use the parent's value
    def included?
      if self.included.nil?
        (parent.nil? ? false : parent.included?)
      else
        self.included
      end
    end
    

    
  end
end
