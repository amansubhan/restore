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
    module Mysql
      
      class Table < ActiveRecord::Base
        set_table_name 'mysql_tables'

        belongs_to :target, :class_name => 'Restore::Target::Base', :foreign_key => 'target_id'
        has_many :logs, :class_name => 'TableLog', :foreign_key => 'table_id', :dependent => :destroy
        belongs_to :database


        def before_create
          self.target_id = target.id if target
        end        

        def last_log
          logs.find(:first,
            :conditions => 'btime is not null',
            :order => 'snapshot_id desc')
        end
        
        def filename
          "table_#{self.name}.sql"
        end
        
        def log_for_snapshot(snapshot)
          logs.find(:first,
            :conditions => "(snapshot_id <= #{snapshot.id} OR snapshot_id IS NULL)",
            :order => 'snapshot_id desc')
        end
       
        def local_path
          ::File.join(database.name, filename)
        end
        
        def included?
          if self.included.nil?
            return database.included?
          else
            self.included
          end
        end
               
      end
    end
  end
end