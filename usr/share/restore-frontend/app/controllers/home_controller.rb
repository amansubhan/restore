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

class HomeController < InstallationController

  def index
    if request.xhr?
      render :update do |page|
        page.replace_html 'home_contents', :partial => 'index' 
      end
      return
    end
  end
  
  def dont_show
    @current_user.use_home_page = false
    @current_user.save
    render :update do |page|
      page.redirect_to :controller => '/targets', :action => 'index' 
    end
  end
  
  def show_terminology
    render :update do |page|
      page.replace_html 'home_contents', :partial => 'terminology' 
    end    
  end
  
end