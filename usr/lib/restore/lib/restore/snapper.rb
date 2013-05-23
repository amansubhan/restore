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

require 'drb'
require 'gettext'


module Restore
  module Snapper
      
    require 'fileutils'
    
    class Base
      include GetText
      bindtextdomain("restore")

      attr_reader :target
      attr_reader :snapshot
      attr_accessor :status_callback
      attr_reader :logger
      
      def initialize(target, snapshot, logger)
        @target, @snapshot, @logger = target, snapshot, logger
        @status_callback = nil
        @status = {}
      end

      def update_status(status={})
        @status.merge!(status)
        unless status_callback.nil?
          status_callback.call(@status)
        end
      end

      def run
        logger.info _("Snapshot started at %s") % [Time.now]
        begin
          run2
        rescue => e
          snapshot.error = e.to_s #+"\n"+e.backtrace.join("\n")
          logger.fatal e.to_s+"\n"+e.backtrace.join("\n")

          if target.owner
            begin
              target.owner.send_error_email(_('Snapshot Error'), _("An error occured while snapshotting target %s: %s") % [target.name, $!.to_s])
            rescue => e
              snapshot.error = e.to_s #+"\n"+e.backtrace.join("\n")
              logger.fatal e.to_s+"\n"+e.backtrace.join("\n")
            end
          end
        end

        snapshot.end_time = Time.now

        # local size is the space this snapshot takes up locally
        snapshot.local_size = snapshot.calculate_local_size

        # snapped size is the same thing, but will not change after pruning
        snapshot.snapped_size = snapshot.local_size
        snapshot.save

        logger.info _("Updating target size")

        # update the size of the target
        target.size = target.snapshots.sum(:local_size)
        target.save

        logger.info _("Snapshot finished at %s. %s in %s seconds (%s).") % [snapshot.end_time, snapshot.snapped_size.to_s+ ' bytes', snapshot.total_time, snapshot.rate.to_s+' bytes/sec' ]
      end

      def run2
        prepare
        execute
        cleanup
      end
      
      def prepare
        update_status(:phase => 'prepare')
        snapshot.prep_start = Time.now
        snapshot.save
      end
      
      def execute
        update_status(:phase => 'execute')
        snapshot.start_time = Time.now
        snapshot.save
      end
      
      def cleanup
        logger.info _("cleaning")
        update_status(:phase => 'cleanup')
      end
            
    end
  end
end
