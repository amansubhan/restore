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

class Reseller::GroupController < Reseller::BaseController

  def new
    @client = @current_user.clients.find(params[:client_id])
    @group = @client.groups.build

    render :update do |page|
      page.replace_html 'appdialog_content', :partial => partial_path('new')
      page << 'show_dialog();'        
    end

  end

  def create
    @client = @current_user.clients.find(params[:client_id])
    @group = @client.groups.build(params[:group])

    @successful = @group.save

    session[:reseller_client_tree].refresh
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'clients', :partial => partial_path('list')
        page << "flash_success(\"" + _("Group '%s' created") % [@group.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => partial_path('new')
        page << "flash_error(\"" + _("Group could not be created") +"\");"
      end
    end
  end

  def edit
    @client = @current_user.clients.find(params[:client_id])
    @group = @client.groups.find(params[:id])

    render :update do |page|
      if @group
        page.replace_html 'appdialog_content', :partial => partial_path('edit')
        page << 'show_dialog();'        
      else

      end
    end
  end

  def update
    @client = @current_user.clients.find(params[:client_id])
    @group = @client.groups.find(params[:id])

    params[:group][:user_ids] ||= nil
    @successful = @group.update_attributes(params[:group])
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'clients', :partial => partial_path('list')
        page << "flash_success(\"" + _("Group '%s' updated") % [@group.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => partial_path('edit')
        page << "flash_error(\"" + _("Group '%s' failed to be updated") % [@group.name] +"\");"
      end
    end

  end  

  def delete
    @client = @current_user.clients.find(params[:client_id])
    @group = @client.groups.find(params[:id])
    @successful = @group.destroy
    session[:reseller_client_tree].refresh

    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'clients', :partial => partial_path('list')
        page << "flash_success(\"" + _("Group '%s' deleted") % [@group.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => partial_path('edit')
        page << "flash_error(\"" + _("Could not delete group '%s'") % [@group.name] +"\");"
      end
    end
  end
end