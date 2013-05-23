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

class Target::SambaController < Target::FilesystemController
  protected
  def update_target_options
    @target.hostname = params[:target][:hostname]
    @target.username = params[:target][:username]
    @target.password = params[:target][:password]
    # call super last, as the filesystem controller
    # re-inits the browser with these values
    super
  end
end