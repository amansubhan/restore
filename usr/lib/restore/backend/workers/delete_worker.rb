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

class DeleteWorker < BaseWorker
  def do_work(args)
    super
    @target_id = args[:target_id]
    Juggernaut.send_data("refresh_target(#{@target_id});", [:targets])
    if target = Restore::Target::Base.find(@target_id)
      target.destroy
    end
    Juggernaut.send_data("refresh_targets();", [:targets])
    self.delete
  end

end
