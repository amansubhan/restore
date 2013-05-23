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
  module Snapshot
    require 'fileutils'
    class Base < ActiveRecord::Base
      set_table_name 'snapshots'
      belongs_to :target, :class_name => 'Restore::Target::Base', :foreign_key => 'target_id'
      
            
      cattr_accessor :snapshot_handles      
      class << self
        @@snapshot_handles ||= {}
      end
      
      def storage
        self.class.snapshot_handles[self.id] ||= target.storage.get_snapshot_handle(self.id)
      end
      
      def before_destroy
        begin
          storage.destroy
        rescue
          return false
        end
        true
      end
            
      def running?
        self.end_time.nil?
      end
      
      def size
        0
      end
      
      def total_time
        end_time - created_at rescue nil
      end
      
      def rate
        snapped_size.to_f/total_time rescue nil
      end

      def short_status
        if self.end_time
          self.error ? 'error' : 'finished'
        elsif self.start_time
          'running'
        else
          'preparing'
        end
      end

      def worker
        if MiddleMan.jobs.keys.include?("snapshot_#{target.id}")
          return MiddleMan.worker("snapshot_#{target.id}")
        end
      end

      def stop
        if w = worker
          MiddleMan.delete_worker("snapshot_#{target.id}")
        end

        if !self.end_time
          self.error = 'Stopped by user'
          self.end_time = Time.now
          save
        end
      end
      
      def dav_resource_class
        require 'restore/dav_resource/snapshot'
        Restore::DavResource::Snapshot
      end

    end
  end
end