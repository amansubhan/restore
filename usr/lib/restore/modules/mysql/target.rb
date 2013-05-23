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
  module Target
    module_require_dependency :mysql, 'database'
    module_require_dependency :mysql, 'table'
    module_require_dependency :mysql, "snapshot"
    
    class Mysql < Restore::Target::Base
      
      has_many :databases, :class_name => 'Restore::Modules::Mysql::Database', :foreign_key => 'target_id', :dependent => :destroy
      #has_many :tables, :class_name => 'Restore::Modules::Mysql::Table', :foreign_key => 'target_id'
      
      # FRONTEND
      # create a human friendly name for the root of the target
      def root_name
        "mysql://#{self.username}@#{self.hostname}#{self.port==3306?'':':'+self.port}"
      end

      def included
        self.extra[:included] ? true : false
      end
      
      def included?
        self.included
      end
      
      def included=(value)
        self.extra ||= {}
        self.extra[:included] = (value ? true : false)
      end
      
      def port
        self.extra ||= {}
        self.extra[:port] ||= 3306
      end
      
      def port=(val)
        self.extra ||= {}
        self.extra[:port] = val.to_i
      end
            
      def self.snapshot_class
        #module_require_dependency :mysql, "snapshot"
        Restore::Snapshot::Mysql
      end
      
    end
  end
end
