# Copyright (c) 2006, 2007 Ruffdogs Software, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

module BackgrounDRb

  class Trigger

    attr_accessor :start_time, :end_time, :repeat_interval

    def initialize(opts={})
      @start_time = opts[:start]
      @end_time = opts[:end]
      @repeat_interval = opts[:repeat_interval]
    end

    def fire_time_after(time)
      @start_time = time  if not @start_time

      # Support UNIX at-style scheduling, by just specifying a start
      # time.
      if @end_time.nil? and @repeat_interval.nil?
        @end_time = start_time + 1
        @repeat_interval = 1
      end

      case
      when @end_time && time > @end_time
        nil
      when time < @start_time
        @start_time
      when @repeat_interval != nil && @repeat_interval > 0
        time + @repeat_interval - ((time - @start_time) % @repeat_interval)
      end
    end

  end

end
