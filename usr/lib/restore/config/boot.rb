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

# Don't change this file. Configuration is done in config/environment.rb and config/environments/*.rb
begin
  require 'rubygems'
rescue LoadError
end

unless defined?(RESTORE_ROOT)
  root_path = File.join(File.dirname(__FILE__), '..')

  unless RUBY_PLATFORM =~ /(:?mswin|mingw)/
    require 'pathname'
    root_path = Pathname.new(root_path).cleanpath(true).to_s
  end
  RESTORE_ROOT = root_path
end

$LOAD_PATH << File.join(RESTORE_ROOT, 'lib')
$LOAD_PATH.uniq!


require File.join(RESTORE_ROOT, 'lib', 'restore')
require File.join(RESTORE_ROOT, 'lib', 'restore', 'installation')
require File.join(RESTORE_ROOT, 'lib', 'restore', 'config')
Restore::Config.load

# snagged from rails, I like it.
unless defined?(Restore::Initializer)
  require "restore/initializer"
  Restore::Initializer.run(:set_load_path)
end

require File.join(RESTORE_ROOT, 'lib', 'restore', 'modules')
Restore::Modules.load
