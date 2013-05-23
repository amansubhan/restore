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

class Target::BaseController < InstallationController  
  after_filter :save_session
  
  cattr_accessor :read_methods
  
  require_dependency 'restore/snapshot'
  
  class << self
    @@readwrite_methods = []
    @@admin_methods = []

    def needs_readwrite_access(*methods)
      @@readwrite_methods += methods
    end

    def needs_admin_access(*methods)
      @@admin_methods += methods
    end
  end
  
  needs_admin_access :update_permissions, :new_role, :create_role, :delete_role, :confirm_delete,
    :new_snapshot_schedule, :create_snapshot_schedule, :edit_snapshot_schedule, :update_snapshot_schedule, :delete_snapshot_schedule, :toggle_snapshot_schedule,
    :new_revision_schedule, :create_revision_schedule, :edit_revision_schedule, :update_revision_schedule, :update_revision_schedule,
    :start, :stop
  
  def index
    add_juggernaut_channel "target_#{@target.id}".to_sym

    setup_panel
    if request.xhr?
      render :update do |page|
        page.replace_html 'appcontent', :partial => partial_path('index')
      end
      return
    end
    render '/target/index'
  end

  def show_panel
    @tsession[:panel] = params[:panel]
    setup_panel
    partial = partial_path(@tsession[:panel])
    render :update do |page|
      page.replace_html 'targetmenu', :partial => partial_path('menu')
      page.replace_html 'targetpanel', :partial => partial
    end
  end

  def refresh_menu
    render :update do |page|
      page.replace_html 'targetmenu', :partial => partial_path('menu')
    end      
  end

  def permissions
    @tsession[:panel] = 'permissions'
    setup_panel
    render :update do |page|
      page.replace_html 'appcontent', :partial => partial_path('index')
    end
  end

  def show_snapshot_info
    @snapshot = @target.snapshots.find(params[:snapshot_id])
    render :update do |page|
      page.replace_html 'snapshot_info_contents', :partial => partial_path('snapshot_info')
      page << "show_info();"
    end
  end

  def update
    update_target_options
    @target.save    
    render :update do |page|
      page.replace_html 'targetpanel', :partial => partial_path('settings')
    end
  end

  def update_permissions
    @target.owner_id = params[:target][:owner_id]
    @target.save
    render :update do |page|
      page.replace_html 'targetpanel', :partial => partial_path('permissions')
    end
  end

  def new_role
    @role = @target.roles.build
    
    render :update do |page|
      page.replace_html 'role_info_content', :partial => partial_path('role_new')
      page << 'show_role_info();'
    end
  end

  def create_role
    @role = @target.roles.build(params[:role])
    @success = @role.save
  
    render :update do |page|
      if @success
        page << 'hide_role_info();'
        page.replace_html 'targetpanel', :partial => partial_path('permissions')        
        page << "flash_success(\"" + _("Role created") +"\");"
        
      else
        page.replace_html 'role_info_content', :partial => partial_path('role_new')
        page << "flash_error(\"" + _("Role could not be created") +"\");"
      end
    end
  end

  def delete_role
    @role = @target.roles.find(params[:role_id])
    @role.destroy
        
    render :update do |page|
      page.replace_html 'targetpanel', :partial => partial_path('permissions')
    end
  end

  def confirm_delete
    @target.background_destroy

    render :update do |page|
      page << remote_function(:url => {:controller => '/targets'})
      #page.redirect_to :controller => '/targets'
      page << "flash_success(\""+_("Deleting target '%s'") % [@target.name]+"\");"
    end
  end

  def new_snapshot_schedule
    @schedule = @target.schedules.build
    @schedule = Restore::Schedule::Simple.new(:target => @target)

    render :update do |page|
      page.replace_html 'snapshot_schedule_info_content', :partial => partial_path('snapshot_schedule_new')
      page << 'show_schedule_info();'
    end
  end

  def create_snapshot_schedule
    if params[:schedule][:type] == 'Simple'
      params[:schedule][:simple_weekdays] ||= []
      @schedule = Restore::Schedule::Simple.new(params[:schedule])
    else
      @schedule = Restore::Schedule::Advanced.new(params[:schedule])
    end
    @schedule.target = @target
    
    @successful = @schedule.save

    setup_panel if @successful

    render :update do |page|
      if @successful
        page.replace_html 'snapshot_schedules', :partial => partial_path('snapshot_schedules')
        page << "flash_success(\"" + _("Snapshot schedule '%s' created") % [@schedule.name] +"\");"
      else
        page.replace_html 'snapshot_schedule_info_content', :partial => partial_path('snapshot_schedule_new')
        page << "flash_error(\"" + _("Could not create snapshot schedule") % [@schedule.name] +"\");"
      end
    end
  end

  def edit_snapshot_schedule
    @schedule = @target.schedules.find(params[:schedule_id])
    render :update do |page|
      page.replace_html 'snapshot_schedule_info_content', :partial => partial_path('snapshot_schedule_edit')
      page << 'show_schedule_info();'
    end
  end

  def update_snapshot_schedule
    @schedule = @target.schedules.find(params[:schedule_id])
    params[:schedule][:simple_weekdays] ||= [] if @schedule[:type] == 'Simple'
    
    @successful = @schedule.update_attributes(params[:schedule])

    render :update do |page|
      if @successful
        page.replace_html 'snapshot_schedules', :partial => partial_path('snapshot_schedules')
        page << "flash_success(\"" + _("Snapshot schedule '%s' updated") % [@schedule.name] +"\");"
      else
        page.replace_html 'snapshot_schedule_info_content', :partial => partial_path('snapshot_schedule_edit')
        page << "flash_error(\"" + _("Snapshot schedule '%s' failed to update") % [@schedule.name] +"\");"
      end
    end
  end

  def delete_snapshot_schedule
    @schedule = @target.schedules.find(params[:schedule_id])
    @successful = @schedule.destroy
    render :update do |page|
      if @successful
        page.replace_html 'snapshot_schedules', :partial => partial_path('snapshot_schedules')
        page << "flash_success(\"" + _("Snapshot schedule '%s' deleted") % [@schedule.name] +"\");"
      else
        page.replace_html 'snapshot_schedule_info_content', :partial => partial_path('snapshot_schedule_edit')
        page << "flash_error(\"" + _("Could not delete snapshot schedule '%s'") % [@schedule.name] +"\");"
      end
    end
  end


  def toggle_snapshot_schedule
    if params[:schedule][:type] == 'Simple'
      @schedule = Restore::Schedule::Simple.new
    else
      @schedule = Restore::Schedule::Advanced.new
    end
    render :update do |page|
      page.replace_html 'snapshot_schedule_info_content', :partial => partial_path('snapshot_schedule_new')
    end    
  end


  def new_revision_schedule
    @revision_schedule = @target.revision_schedules.build
    render :update do |page|
      page.replace_html 'revision_schedule_info_content', :partial => partial_path('revision_schedule_new')
      page << 'show_revision_schedule_info();'
    end
  end

  def create_revision_schedule
    @revision_schedule = @target.revision_schedules.build(params[:revision_schedule])
    @successful = @revision_schedule.save

    setup_panel if @successful

    render :update do |page|
      if @successful
        page.replace_html 'revision_schedules', :partial => partial_path('revision_schedules')
        page << "flash_success(\"" + _("Revision schedule created") +"\");"
      else
        page.replace_html 'revision_schedule_info_content', :partial => partial_path('revision_schedule_new')
        page << "flash_error(\"" + _("Failed to create revision schedule") +"\");"
      end
    end
  end

  def edit_revision_schedule
    @revision_schedule = @target.revision_schedules.find(params[:revision_schedule_id])
    render :update do |page|
      page.replace_html 'revision_schedule_info_content', :partial => partial_path('revision_schedule_edit')
      page << 'show_revision_schedule_info();'
    end
  end

  def update_revision_schedule
    @revision_schedule = @target.revision_schedules.find(params[:revision_schedule_id])
    @successful = @revision_schedule.update_attributes(params[:revision_schedule])

    render :update do |page|
      if @successful
        page.replace_html 'revision_schedules', :partial => partial_path('revision_schedules')
        page << "flash_success(\"" + _("Revision schedule updated") +"\");"
      else
        page.replace_html 'revision_schedule_info_content', :partial => partial_path('revision_schedule_edit')
        page << "flash_error(\"" + _("Revision schedule could not be updated") +"\");"
      end
    end
  end

  def delete_revision_schedule
    @revision_schedule = @target.revision_schedules.find(params[:revision_schedule_id])
    @successful = @revision_schedule.destroy

    render :update do |page|
      if @successful
        page.replace_html 'revision_schedules', :partial => partial_path('revision_schedules')
        page << "flash_success(\"" + _("Revision schedule deleted") +"\");"
      else
        page.replace_html 'revision_schedule_info_content', :partial => partial_path('revision_schedule_edit')
        page << "flash_error(\"" + _("Failed to delete revision schedule") +"\");"
      end
    end
  end


  def start
    if s = @target.running_snapshot
      error = _('A snapshot is already running')
    else
      snapshot = @target.create_snapshot
      @target.start_snapshot(snapshot)
    end

    render :update do |page|
      if error
        page.replace_html 'targetmenu', :partial => partial_path('menu')
        page << "flash_error('#{error}');"
      else
        page << "flash_success(\"" + _("Snapshot started") +"\");"
        @tsession[:panel] = 'console'
        page.replace_html 'targetmenu', :partial => partial_path('menu')
        page.replace_html 'targetpanel', :partial => partial_path('console')
      end
    end
  end


  def stop
    if s = @target.snapshots.last
      s.stop
      render :update do |page|
        page.replace_html 'targetmenu', :partial => partial_path('menu')
        page << "flash_success(\"" + _("Snapshot stopped") +"\");"
        page << "refresh_snapshots();"
      end
    else
      render :nothing
    end
  end

  def update_console
    lines = []
    open(File.join(Restore::Config.log_dir, "target_#{@target.id}.log"), 'r') do |f|
      f.seek(@tsession[:console_tell]) if @tsession[:console_tell]
      f.each do |l|
        lines << Juggernaut.html_escape(l).gsub("\n", '\\n').gsub("'", "\\\\\'")
      end
      @tsession[:console_tell] = f.tell
    end
    render :update do |page|
      lines.each do |l|
        page << "append_log('#{l}');"
      end
      page << "setTimeout(\"console_timer();\", 2000);"
    end
  end


  protected
  def init_session
    session[:target] ||= {}
    if !session[:target][@target.id]
      session[:target][@target.id] = {
        :expanded => {},
        :panel => 'info'}
      if @snapshot = @target.full_snapshots.last
        session[:target][@target.id][:snapshot_id] = @snapshot.id
      end
    end
  end

  def load_session
    @target = ::Restore::Target::Base.find(params[:id])
    if ['index', 'permissions'].include?(params[:action])
      init_session
    end
    @tsession = session[:target][@target.id]
    #@nav_tree_root = @tsession[:nav_tree_root]

    unless @snapshot
      begin
        @snapshot = @target.full_snapshots.find(@tsession[:snapshot_id])
      rescue
        if @snapshot = @target.full_snapshots.last
          @tsession[:snapshot_id] = @snapshot.id
        end
      end
    end
  end

  def save_session
    session[:target][@target.id] = @tsession if @target
  end

  def setup_panel
    case @tsession[:panel]
    when 'info'
      generate_snapshots

    when 'status'
      @workers = MiddleMan.jobs.collect {|key,j|
        if w = MiddleMan.worker(key)
          {:name => key, :results => w.results.to_hash }
        end
      }.compact
    when 'console'
      @tsession[:console_tell] = File.size(File.join(Restore::Config.log_dir, "target_#{@target.id}.log")) rescue 0
    when 'permissions'
    end
  end

  def generate_snapshots
    @snapshots = @target.snapshots  
  end

  def default_url_options(options)
    { :id => @target.id }
  end
  
  def authorized?

    load_session
    
    return false unless super
    if @@readwrite_methods.include?(params[:action].to_sym)
      return true if @current_user.can_readwrite_target?(@target)    
    elsif @@admin_methods.include?(params[:action].to_sym)
      return true if @current_user.can_admin_target?(@target)    
    else # read access is needed for all methods
      return true if @current_user.can_read_target?(@target)    
    end

    false
  end
  
  def update_target_options
    @target.name = params[:target][:name]
    
  end
  
  
  private
  # setup auxiliary paths for these modules
  def initialize_template_class(response)
    super
    klass = self.class
    while klass && klass != Target::BaseController
      if klass.to_s.underscore =~ /\/(\w+)_controller$/
        response.template.aux_paths ||= []
        response.template.aux_paths << "#{RESTORE_ROOT}/modules/#{$1}/views"
      end
      klass = klass.superclass
    end
  end

end