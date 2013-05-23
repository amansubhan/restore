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

module Restore::Module
  module Sftp
    def description
      _("SFTP allows you to connect to Linux and other unix-like hosts over SSH (most secure method)")
    end
    
    def human_name
      _("SFTP")
    end

  end
  Restore::Modules.register(Sftp, :depends => :filesystem)
end
