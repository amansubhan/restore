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

class Target::SftpController < Target::FilesystemController
  
  def install_key
    @success = @target.store_public_key(params[:target][:password])
    setup_settings_browser
    render :update do |page|
      page.replace_html 'targetpanel', :partial => partial_path('settings')
    end
  end
  
  protected
  def update_target_options
    @target.hostname = params[:target][:hostname]
    @target.port = params[:target][:port]
    @target.username = params[:target][:username]
    @target.password = params[:target][:password]
    
    # call super last, as the filesystem controller
    # re-inits the browser with these values
    super
    
  end
end
