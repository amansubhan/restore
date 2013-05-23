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

begin
  require 'rubygems'
rescue LoadError
end

require 'pathname'
RESTORE_BACKEND_ROOT = Pathname.new(File.dirname(__FILE__)).realpath.to_s unless defined?(RESTORE_BACKEND_ROOT)
$LOAD_PATH << RESTORE_BACKEND_ROOT

# load restore lib
require 'restore_path'
$LOAD_PATH << File.join(RESTORE_ROOT, 'lib')

require 'etc'
def switch_user
  return unless restore_user = Restore::Config.user
  pwnam = Etc.getpwnam(restore_user)
  unless Process::UID.eid == pwnam[2]
    Process::GID.change_privilege pwnam[3]
    Process.initgroups pwnam[0], pwnam[3]
    Process::UID.change_privilege pwnam[2]

    ENV['TMPDIR'] = nil
    ENV['TMP'] = nil
    ENV['LOGNAME'] = pwnam[0]
    ENV['USER'] = ENV['LOGNAME']
    ENV['USERNAME'] = ENV['LOGNAME']
    ENV['HOME'] = pwnam[5]
    ENV['SHELL'] = pwnam[6]
  end
end

cmd = ARGV[0]
case cmd
when 'upgrade'
  require 'commands/upgrade'
when 'setup'
  require 'commands/setup'
when 'console'

  require 'commands/console'
when 'snap'
  require 'commands/snap'
when 'clean'
  require 'commands/clean'
when 'duplicate'
  require 'commands/duplicate'
when 'start', 'stop', 'restart', 'run', 'zap'
  require 'commands/backend'
else
  puts "Usage: restore <command> <command_options>"
  puts
  puts "Commands:"
  puts "    setup               Run configuration utility"
  puts "    console             Run ruby console"
  puts "    snap                Run a snapshot"
  puts "    clean               Clean a target (removes all snapshots)"
  puts "    duplicate           Duplicate a target"
  puts "    prune               Cleans old files from a snapshot"
  puts "    start               Start backend server"
  puts "    stop                Stop backend server"
  puts "    run                 Run background server in foreground"
  puts "    zap                 "
  puts
end
