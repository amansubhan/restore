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

require 'workers/base_worker'
class SnapshotWorker < BaseWorker
  def do_work(args)
    super
    @target_id = args[:target_id]
    @last_update = Time.now

    Juggernaut.send_data("refresh_target(#{@target_id});", [:targets])
    Juggernaut.send_data("refresh_snapshots();", ["target_#{@target_id}".to_sym])
    Juggernaut.send_data("snapshot_started_or_stopped();", ["target_#{@target_id}".to_sym])


    @target = Restore::Target::Base.find_by_id(@target_id)
    @snapshot = args[:snapshot_id] ? @target.snapshots.find(args[:snapshot_id]) : @target.create_snapshot

    logdev = BackgrounDRb::TargetLogDev.new(@target_id, "snap_#{@snapshot.id}")
    logger = Logger.new(logdev)

    begin
      @snapper = @target.create_snapper(@snapshot, logger)
      @snapper.run
      begin
        if @target.owner
          @target.owner.send_info_email('Snapshot Completed', "Your snapshot for #{@target.name} has completed.")
        end
      rescue
        # XXX work this out...  perhaps deliver the message to an internal mailbox for the user?
      end
    rescue
      logger.fatal "Error: "+$!.to_s
      @snapshot.error = $!.to_s
      @snapshot.end_time = Time.now
      @snapshot.local_size = 0
      @snapshot.snapped_size = 0
      @snapshot.save
      if @target.owner
        begin
          @target.owner.send_error_email('Snapshot Error', "An error occured while snapshotting target #{@target.name}: #{$!.to_s}")
        rescue
        end
      end
    end

    Juggernaut.send_data("refresh_target(#{@target_id});", [:targets])
    Juggernaut.send_data("refresh_snapshots();", ["target_#{@target_id}".to_sym])
    Juggernaut.send_data("snapshot_started_or_stopped();", ["target_#{@target_id}".to_sym])
    self.delete
  end
end

