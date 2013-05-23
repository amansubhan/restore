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

class ScheduleWorker < BaseWorker
  def do_work(args)
    super
    
    Restore::Schedule::Base.find(:all).each do |s|
      s.schedule_worker
    end
    
    self.delete
  end

end
