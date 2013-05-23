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

require 'erb'

module BackgrounDRb
  VERSION = "0.2.1"
end

# The configuration class is shared between server and the DRb clients
# (Rails MiddleMan, console and the MiddleManDRbObject). Defaults set in
# this class is in turn overridden by options from the configuration
# file, which in turn can be overridden by command line options.
class BackgrounDRb::Config
  def self.setup(override_options)
    Restore::Config.load
  end
end

# The MiddleManDRbObject is primarily used to establish the MiddleMan
# constant in Rail, but it is also possible to use it to create things
# like DRb connections a remote BackgrounDRb server or another server on
# the same host. At a minimum you need to specify a vaild DRb URI.
class BackgrounDRb::MiddleManDRbObject
  def self.init
    require "drb"

    socket = File.join(Restore::Config.socket_dir, 'restore_backend.sock')
    middle_man = DRbObject.new(nil, "drbunix://#{socket}")
    middle_man
  end
end
