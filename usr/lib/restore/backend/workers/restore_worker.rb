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

require 'workers/base_worker'
class RestoreWorker < BaseWorker
  def do_work(args)
    super
    @target_id = args[:target_id]
        
    @target = Restore::Target::Base.find_by_id(@target_id)
    snapshot = @target.snapshots.find(args[:snapshot_id])
    
    logdev = JuggernautLogDev.new(@target_id)
    logger = Logger.new(logdev)
    
    begin
      restorer = @target.create_restorer(snapshot, logger, args[:extra_args])
      restorer.run
    rescue => e
      logger.info $!.to_s
      e.backtrace.each do |l|
        logger.info l
      end
    end
    self.delete
  end
end
