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
    class Advanced < Base # < ActiveRecord::Base

      def schedule_worker
        MiddleMan.schedule_worker(
        :class => 'SnapshotWorker',
        :job_key => "snapshot_#{target.id}",
        :args => {:target_id => target.id },
        :trigger_type => :cron_trigger,
        :trigger_args => "0 #{min} #{hour} #{day} #{month} #{weekday} *"
        )
      end

      def validate
        unless parse_part(min, 0..59)
          errors.add :min, _("Invalid format")
        end

        unless parse_part(hour, 0..23)
          errors.add :hour, _("Invalid format")
        end

        unless parse_part(day, 1..31)
          errors.add :day, _("Invalid format")
        end

        unless parse_part(month, 1..12)
          errors.add :month, _("Invalid format")
        end

        unless parse_part(weekday, 0..6)
          errors.add :weekday, _("Invalid format")
        end
      end

      def parse_part(part, range=nil)

        return false if part.nil?
        return true if part == '*' or part =~ /[*0]\/1/

        valid = true
        part.split(',').each do |p|
          unless (p =~ /(\d+)-(\d+)/) ||  # 0-5
            (p =~ /(\*|\d+)\/(\d+)/ and not range.nil?) ||
            (p =~ /(\d+)/)  # 5
            valid = false
          end
        end
        valid
      end 
      
      def human_string
        "#{min},#{hour},#{day},#{month},#{weekday}"
      end

    end
  end
end