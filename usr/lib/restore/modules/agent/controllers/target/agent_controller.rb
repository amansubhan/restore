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

class Target::AgentController < Target::BaseController
  require 'tree'
  include Tree::ControllerMixin
  
  def set_snapshot
    if @snapshot = @target.full_snapshots.find(params[:snapshot_id])
      @tsession[:snapshot_id] = params[:snapshot_id]
      @tsession[:restore_browser_root].set_snapshot(@snapshot)
    end
    render :update do |page|
      page.replace_html 'targetpanel', :partial => partial_path('restore')
    end
  end
    
  def settings_browser_refresh_object
    object_path = params[:tree_object_path]
    path_array = object_path.split(/\//)

    object = @tsession[:settings_browser_root].find_by_path_array(path_array[1..-1])
    worker = MiddleMan.worker(object.job_key)
    
    if worker && object
      if worker.results[:loaded]
        worker.results[:children].each do |c|
          klass = c[:container] ? AgentSettingsTree::Container : AgentSettingsTree::Object          
          if object.class == AgentSettingsTree::Agent
            parent_object = nil
            parent_id = nil
          else
            parent_id = object.object_id
          end
          
          unless obj = @target.objects.find_by_parent_id_and_name(parent_id, c[:name])
            obj = Restore::Module::Agent::Object::Base.create(
              :name => c[:name],
              :target_id => @target.id,
              :parent_id => parent_id,
              :included => nil
            )
          end
          
          
          c[:type] = nil
          c[:target_id] = @target.id
          c[:target_class] = @target.class
          c[:session_id] = session.session_id
          c[:selected] = parent_object.nil? ? object.selected : obj.included?
          
          object << klass.new(CGI::escape(c[:name]), obj, c)

        end
        object.loaded = true
      elsif worker.results[:error]
        object.error = worker.results[:error]
      end
      worker.delete
    end

    render :update do |page|
      if object.loaded
        page.replace object.path, :partial => partial_path(object.partial_name), :locals => {:object => object}
        object.children_values.reverse.each do |c|
          page.insert_html :after, object.path, :partial => partial_path(c.partial_name), :locals => {:object => c}
        end
      elsif object.error
        page.replace object.path, :partial => partial_path(object.partial_name), :locals => {:object => object}        
      end
    end # render
  end
  
  
  protected
  def setup_panel
    super
    case @tsession[:panel]
    when 'restore'
      setup_restore_browser
    when 'settings'
      setup_settings_browser
    end
  end

  def setup_restore_browser
    @tsession[:restore_browser_root] ||= AgentRestoreTree::Agent.new(@target, @snapshot)
  end

  def setup_settings_browser
    @tsession[:settings_browser_root] = AgentSettingsTree::Agent.new(
      @target,
      :session_id => session.session_id
    )
  end

  def find_tree(id)
    if id == 'restore_browser'
      @tsession[:restore_browser_root]
    elsif id == 'settings_browser'
      @tsession[:settings_browser_root]
    end
  end

  def update_target_options
    super
    @target.hostname = params[:target][:hostname]
    @target.port = params[:target][:port]
    setup_settings_browser
  end


end
