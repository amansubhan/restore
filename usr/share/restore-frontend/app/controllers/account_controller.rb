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

class AccountController < ApplicationController
  before_filter :authenticate
  
  def index
    @account = @current_user
    render :update do |page|
      page.replace_html 'appdialog_content', :partial => 'form'
      page << "show_dialog();"
    end
  end

  def update
    @successful = @current_user.update_attributes(params[:account])
    render :update do |page|
      if @successful
        page << 'hide_dialog();'
        page << "flash_success(\""+_('Account information updated')+"\");"
      else
        page.replace_html 'appdialog_content', :partial => 'form'
        page << "flash_error(\""+_('Account information failed to be updated')+"\");"
      end
    end
  end

end