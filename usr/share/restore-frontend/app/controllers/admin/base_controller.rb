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

class Admin::BaseController < InstallationController
  
  layout 'admin'
  def index
    if request.xhr?
      render :update do |page|
        page.replace_html 'appcontent', :partial => partial_path('index')
      end
    else
      render :partial => partial_path('index'), :layout => true 
    end
  end
    
  protected
  def authorized?
    super    
    @current_user.is_admin?
  end
  

end