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
    class Simple < Advanced

      def simple_weekdays
        if self.weekday == '*'
          [0, 1, 2, 3, 4, 5, 6]
        else
          self.weekday.split(',').collect{|i| i.to_i}
        end
      end

      def simple_weekdays=(val)
        self.weekday = val.join(',')
      end
      
      def simple_weekday_options
        available_weekdays.collect{|wd|
          [wd, available_weekdays.index(wd)]
        }
      end
      
      def simple_time
        self.hour.to_i
      end

      def simple_time=(val)
        self.min = '0'
        self.hour = val
      end

      def simple_time_options
        hour_options = []
        0.upto(23) do |hour|
          hour_options << [sprintf("%02d:00", hour), hour]
        end
        hour_options
      end
      
      def human_string
        buffer = sprintf("%02d:00", self.hour)
        buffer += " on "
        buffer += simple_weekdays.collect { |num|
          available_weekdays[num.to_i]
        }.join(', ')
        
      end
      
      def available_weekdays
        ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
      end
            
      def validate
        super
        if self.weekday == ''
          errors.add :simple_weekdays, _("You must choose at least one weekday")
        end
      end
      
    end
  end
end