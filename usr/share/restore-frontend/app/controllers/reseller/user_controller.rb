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

class Reseller::UserController < Reseller::BaseController
      
  def new
    @client = @current_user.clients.find(params[:client_id])
    @user = @client.users.build
    
    render :update do |page|
      page.replace_html 'appdialog_content', :partial => partial_path('new')
      page << 'show_dialog();'        
    end
    
  end
  
  def create
    @client = @current_user.clients.find(params[:client_id])
    @user = @client.users.build(params[:user])

    @successful = @user.save

    session[:reseller_client_tree].refresh

    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'clients', :partial => partial_path('list')
        page << "flash_success(\"" + _("User '%s' created") % [@user.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => partial_path('new')
        page << "flash_error(\"" + _("User could not be created") +"\");"
      end
    end
  end

  def edit
    @client = @current_user.clients.find(params[:client_id])
    @user = @client.users.find(params[:id])
    
    render :update do |page|
      if @user
        page.replace_html 'appdialog_content', :partial => partial_path('edit')
        page << 'show_dialog();'        
      else
        
      end
    end
  end
  
  def update
    @client = @current_user.clients.find(params[:client_id])
    @user = @client.users.find(params[:id])

    # we have to do this in the case where we remove all group memberships
    params[:user][:group_ids] ||= nil
    @successful = @user.update_attributes(params[:user])

    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'clients', :partial => partial_path('list')
        page << "flash_success(\"" + _("User '%s' updated") % [@user.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => partial_path('edit')
        page << "flash_error(\"" + _("User '%s' failed to be updated") % [@user.name] +"\");"
      end
    end
  end

  def delete
    @client = @current_user.clients.find(params[:client_id])
    @user = @client.users.find(params[:id])
    @successful = @user.destroy
    session[:reseller_client_tree].refresh
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'clients', :partial => partial_path('list')
        page << "flash_success(\"" + _("User '%s' deleted") % [@user.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => partial_path('edit')
        page << "flash_error(\"" + _("Could not delete user '%s'") % [@user.name] +"\");"
      end
    end
    
  end

  def switch_to    
    @client = @current_user.clients.find(params[:client_id])
    @user = @client.users.find(params[:id])

    # store all of the old session in a new session key
    old_session = session.data.clone
    session.data.keys.each do |k|
      session.data.delete k
    end
    session[:old_sessions] ||= []
    session[:old_sessions] << old_session
        
    session[:user_id] = @user.id
    render :update do |page|
      page.redirect_to url_for(:controller => @user.default_controller)
    end
  end

  
end