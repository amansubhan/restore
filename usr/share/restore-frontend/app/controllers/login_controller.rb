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

class LoginController < ApplicationController
  
  def index
    # this is for handling a logout from a switched user session    
    if session[:old_sessions] &&
      (old_session = session[:old_sessions].pop) &&
      (user = Restore::Account::Base.find(old_session[:user_id]) rescue nil)
      old_session = old_session.clone
      session.data.keys.each do |k|
        session.data.delete k
      end
      old_session.each_pair do |k,v|
        session[k] = v
      end
      redirect_to :controller => user.default_controller
    else
      reset_session
    end
  end
  
  def login
    if @current_user = Restore::Account::Base.authenticate(params[:user][:username], params[:user][:password])
      session[:user_id] = @current_user.id
      session[:last_action] = Time.now
      if session[:return_to]
        redirect_to_path(session[:return_to])
        session[:return_to] = nil
      else
        redirect_to :controller => @current_user.default_controller
      end
    else
      @error = _('Login failed')
      render :action => 'index'
    end
  end
end