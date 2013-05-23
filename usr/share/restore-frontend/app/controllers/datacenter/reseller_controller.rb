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

class Datacenter::ResellerController < Datacenter::BaseController
  
  layout 'datacenter'
  
  def new
    @reseller = Restore::Account::Reseller.new
    render :update do |page|
      page.replace_html 'appdialog_content', :partial => 'new'
      page << 'show_dialog();'        
    end
  end
  
  def create
    @reseller = Restore::Account::Reseller.new(params[:reseller])
    @successful = @reseller.save
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'resellers', :partial => 'list'
        page << "flash_success(\"" + _("Reseller '%s' created") % [@reseller.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => 'new'
        page << "flash_error(\"" + _("Reseller could not be created") +"\");"
      end
    end
  end

  def edit
    @reseller = Restore::Account::Reseller.find(params[:id])
    
    render :update do |page|
      if @reseller
        page.replace_html 'appdialog_content', :partial => 'edit'
        page << 'show_dialog();'        
      else
        
      end
    end
  end
  
  def update
    @reseller = Restore::Account::Reseller.find(params[:id])
    @successful = @reseller.update_attributes(params[:reseller])
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'resellers', :partial => 'list'
        page << "flash_success(\"" + _("Reseller '%s' updated") % [@reseller.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => 'edit'
        page << "flash_error(\"" + _("Reseller '%s' failed to update") % [@reseller.name] +"\");"
      end
    end
  end
  
  def delete
    @reseller = Restore::Account::Reseller.find(params[:id])
    @successful = @reseller.destroy
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'resellers', :partial => 'list'
        page << "flash_success(\"" + _("Reseller '%s' deleted") % [@reseller.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => 'edit'
        page << "flash_error(\"" + _("Could not delete reseller '%s'") % [@reseller.name] +"\");"
      end
    end
  end
    
  def switch_to
    if @reseller = Restore::Account::Reseller.find(params[:id])
      # store all of the old session in a new session key
      old_session = session.data.clone
      session.data.keys.each do |k|
        session.data.delete k
      end
      session[:old_sessions] ||= []
      session[:old_sessions] << old_session
      
      session[:user_id] = @reseller.id
      render :update do |page|
        page.redirect_to url_for(:controller => @reseller.default_controller)
      end
    end
  end
  
end