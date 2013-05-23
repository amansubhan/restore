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

class Reseller::ClientController < Reseller::BaseController
  

  def new
    @client = @current_user.clients.build
    @user = @client.users.build
    
    render :update do |page|
      page.replace_html 'appdialog_content', :partial => partial_path('new')
      page << 'show_dialog();'        
    end
    
  end
  
  def create
    @client = @current_user.clients.build(params[:client])
    @successful = false
    Restore::Client.transaction do
      @successful = @client.save
      @user = @client.users.build(params[:user])
      @user.admin = true
      @user.email_info = true
      @user.email_errors = true
      @successful = @user.save!
    end
    
    session[:reseller_client_tree].refresh
      
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'clients', :partial => partial_path('list')
        page << "flash_success(\"" + _("Client '%s' created") % [@client.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => partial_path('new')
        page << "flash_error(\"" + _("Client could not be created") +"\");"
      end
    end
  end

  def edit
    @client = @current_user.clients.find(params[:id])
    
    render :update do |page|
      if @client
        page.replace_html 'appdialog_content', :partial => partial_path('edit')
        page << 'show_dialog();'        
      else
        
      end
    end
  end
  
  def update
    @client = @current_user.clients.find(params[:id])
    
    @successful = @client.update_attributes(params[:client])
    session[:reseller_client_tree].refresh
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'clients', :partial => partial_path('list')
        page << "flash_success(\"" + _("Client '%s' updated") % [@client.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => partial_path('edit')
        page << "flash_error(\"" + _("Client '%s' failed to be updated") % [@client.name] +"\");"
      end
    end
  end
  
  def delete
    @client = @current_user.clients.find(params[:id])
    @successful = @client.destroy
    session[:reseller_client_tree].refresh
    
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'clients', :partial => partial_path('list')
        page << "flash_success(\"" + _("Client '%s' deleted") % [@client.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => partial_path('edit')
        page << "flash_error(\"" + _("Could not delete client '%s'") % [@client.name] +"\");"
      end
    end
    
  end
  
end