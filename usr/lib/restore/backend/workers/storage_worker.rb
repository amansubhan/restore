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
class StorageWorker < BaseWorker
  def do_work(args)
    super

    require 'restore_sd'
    socket = File.join(Restore::Config.socket_dir, "restore_storage.sock")
    File.unlink(socket) if File.exist?(socket)

    require 'drb/timeridconv'
    DRb.install_id_conv DRb::TimerIdConv.new
    
    DRb.start_service("drbunix://"+socket, RestoreSD::Server.new)
    DRb.thread.join
    File.unlink(socket)
    self.delete
  end
  
  #def get_target_handle(target_id)
  #  RestoreSD::TargetHandle.new(target_id)
  #end
  
end

