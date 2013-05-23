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

class TargetsController < InstallationController
  before_filter :load_session

  def index
    add_juggernaut_channel :targets
    
    @targets = @current_install.targets.reject{|t| !@current_user.can_read_target?(t)}
    
    # sounds like something for a model...
    # we do this to only total the targets listed.
    # for admin, that'd be all targets
    @targets_sum = @targets.inject(0) {|sum,t| sum + t.size}
    
    if request.xhr?
      render :update do |page|
        page.replace_html 'appcontent', :partial => 'list'
      end
      return
    end
  end
  
  def refresh_target
    id = params[:id]
    t = @current_user.targets.find(id) rescue nil
    render :update do |page|
      if t
        page.replace "target[#{id}]", :partial => 'target', :locals => {:target => t}
      else
        page.replace "target[#{id}]", ''        
      end
    end
  end
  
  def new
    render :update do |page|
      page.replace_html 'appcontent', :partial => 'new'
    end
  end
  
  def start_wizard
    type = params[:type_select]
    if type
      render :update do |page|
        page << remote_function(:url => {:controller => "/wizard/#{type}"})
      end
    else
      @error = _("Please choose a target type")
      render :update do |page|
        page.replace_html 'appcontent', :partial => 'new'
      end
    end    
  end
  
  def select_target
    old_selection = session[:targets][:selected]
    selection = params[:target_id]
    session[:targets][:selected] = params[:target_id]

    render :update do |page|
      page["target[#{old_selection}]"].removeClassName('selected') if old_selection
      page["target[#{selection}]"].addClassName('selected')
      page.replace_html 'buttons', :partial => 'buttons'
    end  
  end
  
  def permissions
    
  end
  
  protected
  def load_session
    session[:targets] ||= { :selected => nil }
  end
  
end