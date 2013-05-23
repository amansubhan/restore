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

class InstallationController < ApplicationController
  # this is a base class for the main application.
  # think of it as an authorizer for everything
  # underneath the Restore::Client object in the
  # datacenter edition of restore

  before_filter :authenticate
  before_filter :authorize    

  protected
  def authorized?    

    
    return false if @current_user.class != Restore::Account::User
        
    if dc_edition?
      @current_client = @current_user.client if dc_edition?
      @current_install = @current_user.installation
    else
      @current_install = Restore::Installation::Enterprise.new
    end
    true
  end
  
  
end