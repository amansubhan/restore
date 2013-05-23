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

require File.join(RESTORE_ROOT, 'config', 'environment')  

switch_user

if (id = ARGV[1]) && target = Restore::Target::Base.find(id)
  target.clean_snapshots
else
  
  # clean failed snapshots
  Restore::Snapshot::Base.find(:all).each do |s|
    if s.end_time.nil?
      s.destroy
    end
    
  end
  
  
end
