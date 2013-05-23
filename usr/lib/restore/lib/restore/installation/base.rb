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

class Restore::Installation::Base

  def space_percentage
    if quota == 0
      0.0
    else
      (size.to_f/quota)*100 rescue 0.0
    end
  end

  def available_space
    quota - size
  end
  
  def targets_for_user(user)
    targets.reject{|t| !user.can_read_target?(t)}
  end

end
