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

require File.join(RESTORE_ROOT, 'config', 'boot')  
switch_user

irb = RUBY_PLATFORM =~ /(:?mswin|mingw)/ ? 'irb.bat' : 'irb'

require 'optparse'
options = { :irb => irb }
OptionParser.new do |opt|
  opt.banner = "Usage: console [environment] [options]"
  opt.on("--irb=[#{irb}]", 'Invoke a different irb.') { |v| options[:irb] = v }
  opt.parse!(ARGV)
end

libs =  " -r irb/completion"
libs << " -r #{RESTORE_ROOT}/config/environment"


ENV['RESTORE_ENV'] = ARGV[1] || ENV['RESTORE_ENV'] || 'development'
puts "Loading #{ENV['RESTORE_ENV']} environment."

exec "#{options[:irb]} #{libs} --simple-prompt"
