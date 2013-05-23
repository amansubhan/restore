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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  init_gettext "restore-frontend", :locale_path => File.join(RESTORE_ROOT, 'locale')
  
  
  session :session_key => 'restore'
  layout 'application'
  
  before_filter :massage_session
  after_filter :save_url
    
  filter_parameter_logging "password"
  
  require_dependency 'restore/target'
  require_dependency 'restore/snapshot'
  require_dependency 'restore/account'
  
  Restore::Modules.require_dependencies
  
  def toggle_tree_item
    matches = /^(.+?)(\[.+)+/.match(params[:tree_item_id])
    matches = /^(.+)$/.match(params[:tree_item_id]) unless matches
    tree_id = matches[1] rescue nil
    item_id = matches[0] rescue nil

    root = find_tree(tree_id)
    if tree_id && root && (item = root.find_by_id(item_id))
      item.toggle_expanded
      render :update do |page|
        page.replace item.full_id, :partial => partial_path(item.partial_name), :locals => {:item => item}
        
        def expand_item(p, i)
          i.children_values.reverse.each do |c|
            p.insert_html :after, i.full_id, :partial => partial_path(c.partial_name),
              :locals => {:item => c}
            
            expand_item(p, c) if c.expanded
          end
        end

        def collapse_item(p, i)
          if i.children
            i.children.each do |id,c|
              p << "if ($('#{c.full_id}'))"
              p.replace c.full_id, ''
              collapse_item(p, c)
            end
          end
        end

        if item.expanded
          expand_item(page, item) 
        else
          collapse_item(page, item)
        end
      end # render
    else
      render :nothing => true
    end # item
  end
  
  def select_tree_item
    matches = /^(.+?)(\[.+)+/.match(params[:tree_item_id])
    matches = /^(.+)$/.match(params[:tree_item_id]) unless matches
    tree_id = matches[1] rescue nil
    item_id = matches[0] rescue nil

    if tree_id && (root = find_tree(tree_id)) && (item = root.find_by_id(item_id))
      item.selected = params[:value] == '1' ? true : false
      
      if params[:deselect_parent] && !item.selected && item.parent
        item.parent.selected = false
      end
      
      if item.children
        item.all_children.each do |c|
          c.selected = params[:value] == '1' ? true : false
        end
      end
      render :update do |page|
        if item.children && item.expanded
          item.all_children.each do |c|
            page << "if($('#{c.full_id}'))"
            page.replace c.full_id, :partial => partial_path(c.partial_name), :locals =>{:item => c}
          end        
        end
        if params[:deselect_parent] && !item.selected && item.parent
          page << "if($('#{item.parent.full_id}'))"
          page.replace item.parent.full_id, :partial => partial_path(item.parent.partial_name), :locals =>{:item => item.parent}
        end
        page << "if($('#{item.full_id}'))"
        page.replace item.full_id, :partial => partial_path(item.partial_name), :locals =>{:item => item}
      end
    else
      render :nothing => true
    end
  end




  def super_partial_path(partial)
    klass = self.class
    while (klass = klass.superclass) && klass.method_defined?(:controller_path)
      if template_exists?("#{klass.controller_path}/_#{partial}")
        return "#{klass.controller_path}/#{partial}"
      end
    end
    return partial
  end

  def partial_path(partial)
    if template_exists?("#{self.class.controller_path}/_#{partial}")
      return "/#{self.class.controller_path}/#{partial}"
    else
      return super_partial_path(partial)
    end
  end

  def disableflash
    session[:noflash]
    render :nothing => true
  end
  
  protected
  def authenticate
    if session[:user_id] && (@current_user = Restore::Account::Base.find(session[:user_id]) rescue nil)
      true
    else
      if request.xhr?
        render :update do |page|
          page.redirect_to :controller => '/login'
        end
      else
        redirect_to :controller => '/login'
      end
      false
    end
  end
  
  def massage_session
    session[:juggernaut_channels] ||= {}
    session[:juggernaut_channels]['default_channel'] ||= {:controller => nil}
    session[:juggernaut_channels].each_pair do |k,v|
      unless v[:controller].nil? || (v[:controller] == params[:controller])
        session[:juggernaut_channels].delete(k)
        if request.xhr?
          Juggernaut.remove_channel(session.session_id, k)
        end
      end
    end
  end
  
  def save_url
    session[:last_uri] = request.env['REQUEST_URI']
  end
  
  def add_juggernaut_channel(chan, controller_specific = true)
    session[:juggernaut_channels][chan] = {:controller => (controller_specific ? params[:controller] : nil)}
    Juggernaut.add_channel(session.session_id, chan) if request.xhr?
  end

  def authorized?
    true
  end
  
  def authorize

    if !authorized?
      if request.xhr?
        render :update do |page|
          page << "flash_error('#{_('Access denied')}');"
        end
      else
        # do... something?
        redirect_to :controller => '/login'
      end
      return false
    else
      # we're authorized
      return true
    end
  end


  
end
