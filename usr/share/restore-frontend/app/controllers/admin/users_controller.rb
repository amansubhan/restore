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

class Admin::UsersController < Admin::BaseController
  
  def new
    @user = @current_install.build_user
    
    render :update do |page|
      page.replace_html 'appdialog_content', :partial => 'new'
      page << 'show_dialog();'        
    end
    
  end
  
  def create
    @user = @current_install.build_user(params[:user])
    @successful = @user.save
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'admin_content', :partial => 'list'
        page << "flash_success(\"" + _("User '%s' created") % [@user.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => 'new'
        page << "flash_error(\"" + _("User could not be created")+"\");"
      end
    end
  end

  def edit
    @user = @current_install.find_user(params[:id])
    
    render :update do |page|
      if @user
        page.replace_html 'appdialog_content', :partial => 'edit'
        page << 'show_dialog();'        
      else
        
      end
    end
  end
  
  def update
    @user = @current_install.find_user(params[:id])
    @successful = @user.update_attributes(params[:user])
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'admin_content', :partial => 'list'
        page << "flash_success(\"" + _("User '%s' updated") % [@user.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => 'edit'
        page << "flash_error(\"" + _("User '%s' failed to save") % [@user.name] +"\");"
      end
    end
  end

  def delete
    @user = @current_install.find_user(params[:id])
    @successful = @user.destroy
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'admin_content', :partial => 'list'
        page << "flash_success(\"" + _("User '%s' deleted") % [@user.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => 'edit'
        page << "flash_error(\"" + _("Could not delete user '%s'") % [@user.name] +"\");"
      end
    end
    
  end
end