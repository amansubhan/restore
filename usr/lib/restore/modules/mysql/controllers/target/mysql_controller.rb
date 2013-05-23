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


class Target::MysqlController < Target::BaseController
  module_require_dependency :mysql, 'target'
  def set_snapshot
    if @snapshot = @target.full_snapshots.find(params[:snapshot_id])
      @tsession[:snapshot_id] = params[:snapshot_id]
      @tsession[:browse_server].set_snapshot(@snapshot)
    end
    render :update do |page|
      page.replace_html 'targetpanel', :partial => partial_path('browse')
    end
  end

  def browser_show_table_info
    table_id = params[:table_id].to_i
    @table = @target.tables.find(table_id)
    @log = @table.log_for_snapshot(@snapshot)

    render :update do |page|
      page.replace_html :browser_object_info_content, :partial => partial_path('browse_table_info'), :locals => {:table => @table, :log => @log}
      page << 'show_info();'
    end
  end

  protected
  def setup_panel
    super
    case @tsession[:panel]
    when 'browse'
      @tsession[:browse_server] = MysqlTargetTree::Server.new(@target, @snapshot)
    when 'settings'
      setup_settings_browser
    when 'restore'
    end
  end
  
  def setup_settings_browser
    @tsession[:settings_browser] = MysqlSettingsTree::Server.new(@target)
  end
  
  def find_tree(id)
    if id == 'settings_browser_root'
      @tsession[:settings_browser]
    elsif id == 'server'
      @tsession[:browse_server]
    end
  end
  
  def update_target_options
    super
    @target.hostname = params[:target][:hostname]
    @target.port = params[:target][:port]
    @target.username = params[:target][:username]
    @target.password = params[:target][:password]
    setup_settings_browser
  end

end
