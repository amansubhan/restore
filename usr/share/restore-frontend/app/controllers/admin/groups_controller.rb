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

class Admin::GroupsController < Admin::BaseController
  
  def new
    @group = @current_install.build_group
    
    render :update do |page|
      page.replace_html 'appdialog_content', :partial => 'new'
      page << 'show_dialog();'        
    end
  end
  
  def create
    @group = @current_install.build_group(params[:group])
    @successful = @group.save
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        
        page.replace_html 'admin_content', :partial => 'list'
        page << "flash_success(\"" + _("Group '%s' created") % [@group.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => 'new'
        page << "flash_error(\""+_('Group could not be created')+"\");"
      end
    end
  end

  def edit
    @group = @current_install.find_group(params[:id])
    
    render :update do |page|
      if @group
        page.replace_html 'appdialog_content', :partial => 'edit'
        page << 'show_dialog();'
      end
    end
  end
  
  def update
    @group = @current_install.find_group(params[:id])
    
    @successful = @group.update_attributes(params[:group])
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'admin_content', :partial => 'list'
        page << "flash_success(\"" + _("Group '%s' updated") % [@group.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => 'edit'
        page << "flash_error(\"" + _("Group '%s' failed to save") % [@group.name] +"\");"
      end
    end
  end

  def delete
    @group = @current_install.find_group(params[:id])
    
    @successful = @group.destroy
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page.replace_html 'admin_content', :partial => 'list'
        page << "flash_success(\"" + _("Group '%s' deleted") % [@group.name] +"\");"
      else
        page.replace_html 'appdialog_content', :partial => 'edit'
        page << "flash_error(\"" + _("Could not delete group '%s'") % [@group.name] +"\");"
      end
    end 
  end
  
end