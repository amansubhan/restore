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

# we can't load the rails environment here.

require File.join(RESTORE_ROOT, 'lib', 'restore', 'config')
Restore::Config.load
switch_user

require 'fileutils'
[Restore::Config.socket_dir, Restore::Config.pid_dir].each { |dir_to_make| FileUtils.mkdir_p(dir_to_make) }

require 'backgroundrb_server'
BackgrounDRb::Server.new.run