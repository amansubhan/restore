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
  module Schedule
    class Base < ActiveRecord::Base
      set_table_name 'target_schedules'

      belongs_to :target, :class_name => 'Restore::Target::Base', :foreign_key => 'target_id'

      validates_presence_of :name
      validates_uniqueness_of :name, :scope => :target_id

      def after_save
        self.class.reload_schedules
      end

      def after_destroy
        self.class.reload_schedules
      end

      # this is a hack...  maybe when backgroundrb gets more mature
      # we can unload a particular schedule and load it again
      def self.reload_schedules
        MiddleMan.unschedule_all

        find(:all).each do |s|
          s.schedule_worker
        end
      end

      def schedule_worker
        raise "abstract function!"
      end
    end

  end
end