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

require File.join(File.dirname(__FILE__), 'boot')

Restore::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  config.database_configuration_file = File.join(CONFIG_PATH, 'database.yml')
  config.log_path = File.join(Restore::Config.log_dir, 'restore.log')
    
end
require 'override'
require 'backgroundrb'

MiddleMan = BackgrounDRb::MiddleManDRbObject.init

require_dependency 'restore/target'
require_dependency 'restore/snapshot'
Restore::Modules.require_dependencies

