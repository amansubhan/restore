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

class Reseller::BaseController < ApplicationController

  before_filter :authenticate
  before_filter :authorize
  
  layout 'reseller'
  
  def index
    if session[:reseller_client_tree]
      session[:reseller_client_tree].refresh
    else
      session[:reseller_client_tree] = ResellerClientTree::Root.new(@current_user)
    end
    
  end
  
  
  
  protected
  def authorized?
    return false if @current_user.class != Restore::Account::Reseller
    true
  end

  def find_tree(id)
    if id == 'reseller'
      session[:reseller_client_tree]
    end
  end
  
    
end