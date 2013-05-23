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

module Restore
  module Installation

    if File.exist?(File.join(RESTORE_ROOT, 'lib', 'restore', 'installation', 'data_center.rb'))
      require 'restore/installation/data_center'
    elsif  File.exist?(File.join(RESTORE_ROOT, 'lib', 'restore', 'installation', 'enterprise.rb'))
      require 'restore/installation/enterprise'
    else
      raise "no installation type can be loaded"
    end
  end
end
