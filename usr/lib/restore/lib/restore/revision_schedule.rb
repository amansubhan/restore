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

require 'gettext'

module Restore
  class RevisionSchedule < ActiveRecord::Base
    include GetText
    bindtextdomain("restore")    

    belongs_to :target, :class_name => 'Restore::Target::Base', :foreign_key => 'target_id'
    
    
    class << self
      def available_intervals
        [['All', 0],['Hourly', 1.hour], ['Daily', 1.day], ['Weekly', 1.week], ['Monthly', 1.month], ['Yearly', 1.year]]
      end

      def available_units
        ['minute', 'hour', 'day', 'week', 'month', 'year', 'ever']
      end
    end
    
    validates_inclusion_of :interval, :in => available_intervals.collect {|i| i[1]}
    validates_inclusion_of :since_unit, :in => available_units
    validates_presence_of :since, :if => Proc.new {|rec| rec.since_unit != 'ever'}, :message => _("You must supply a time unit")

    
    def interval_string
      case interval
      when 0:
        'all'
      when 1.hour:
        'hourly'
      when 1.day:
        'daily'
      when 1.week:
        'weekly'
      when 1.month:
        'monthly'
      when 1.year:
        'yearly'
      else
        "#{interval}-seconds"
      end
    end

    def since_string
      if since_unit == 'ever'
        'ever'
      else
        unit = since_unit
        unit = unit.pluralize if self.since > 1
        "#{since} #{unit}"
      end
    end
    
    def calc_since(now)
      case since_unit
      when 'ever'
        Time.at(0)
      when 'minute'
        now - since.minutes
      when 'hour'
        now - since.hours
      when 'day'
        now - since.days
      when 'week'
        now - since.weeks
      when 'month'
        now - since.months
      when 'year'
        now - since.years
      end
    end

    
  end
end
