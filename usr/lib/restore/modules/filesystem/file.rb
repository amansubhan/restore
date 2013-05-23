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
  module Modules
    module Filesystem
      class File < ActiveRecord::Base
        set_table_name 'filesystem_files'
        belongs_to :target, :class_name => 'Restore::Target::Base', :foreign_key => 'target_id'
        has_many :logs, :class_name => 'Log', :foreign_key => 'file_id', :dependent => :delete_all
        
        acts_as_tree :scope => 'target_id', :order => 'filename'
        
        def before_create
          self.target_id = target.id if target
          self.parent_id = parent.id if parent
        end

        def last_any_log
          logs.find(:first, :order => 'snapshot_id desc')
        end
    
        def last_log
          logs.find(:first,
            :conditions => 'btime is not null',
            :order => 'snapshot_id desc')
        end
        
        def log_for_snapshot(snapshot)
          logs.find(:first,
            :conditions => "(snapshot_id <= #{snapshot.id} OR snapshot_id IS NULL)",
            :order => 'snapshot_id desc')
        end
        
        def deep_included?
          # we're included, so yes
          return true if included?
          children.each do |c|
            #if any children are deep included, we are deep included
            return true if c.deep_included?
          end
          return false
        end
        
        def all_children
          children + children.collect {|f|
            f.all_children
          }.flatten.compact
        end
        
        
        def children_ids
          children.collect {|f|
            f.id
          }.flatten.compact
        end
        
        def all_children_ids
          children.collect {|f|
            [f.id, f.all_children_ids]
          }.flatten.compact
        end

        
        def nesting
          if parent.nil?
            0
          else
            parent.nesting + 1
          end
        end
        
        def parents
          if parent.nil?
            []
          else
            parent.parents + [parent]
          end
        end
        
        def included?
          if self.included.nil?
            
            if parent.nil?
              return false
            else
              return parent.included?
            end
          else
            self.included
          end
        end
        
      end
    end
  end
end
