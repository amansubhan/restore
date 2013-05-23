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
      class Log < ActiveRecord::Base
        set_table_name 'mysql_logs'
        
        belongs_to :snapshot, :class_name => 'Restore::Snapshot::Base', :foreign_key => 'snapshot_id'
        belongs_to :target, :class_name => 'Restore::Target::Base', :foreign_key => 'target_id'
        
        serialize :extra, Hash
        
        def before_create
          self.target_id = target.id if target
        end
       
        
      end
    end
  end
end