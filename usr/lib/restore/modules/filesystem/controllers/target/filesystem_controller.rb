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

require 'zipper'
class Target::FilesystemController < Target::BaseController
    
  def set_snapshot
    if @snapshot = @target.full_snapshots.find(params[:snapshot_id])
      @tsession[:snapshot_id] = params[:snapshot_id]
      @tsession[:browse_server].set_snapshot(@snapshot)
    end
    render :update do |page|
      page.replace_html 'targetpanel', :partial => partial_path('browse')
    end
  end

  def browser_show_file_info
    file_id = params[:file_id].to_i
    @file = @target.files.find(file_id)
    @log = @file.log_for_snapshot(@snapshot)

    render :update do |page|
      page.replace_html :browser_file_info_content, :partial => partial_path('browse_file_info'), :locals => {:file => @file, :log => @log}
      page << 'show_file_info();'
    end
  end
  
  
  def show_restore_options
    render :update do |page|
      page.replace_html 'appdialog_content', :partial => partial_path('restore_options')
      page << 'show_dialog();'
    end
  end

  def restore
    if params[:type] == 'zipfile'
      render :update do |page|
        page << 'hide_dialog();'
        page.redirect_to :action => 'restore_zip'
      end
    elsif params[:type] == 'inplace' || params[:type] == 'subdir'
      if @target.restore_running?
        render :update do |page|
          page.alert('a restore is already running')
        end
      else
        subdir = (params[:type] == 'inplace') ? '' : params[:subdir]
        
        @target.start_restorer(@snapshot.id, :subdir => subdir, :file_ids => @tsession[:browse_server].all_selected.collect{|f| f.id.to_i})
        render :update do |page|
          page << 'hide_dialog();'
          @tsession[:panel] = 'console'
          page.replace_html 'targetmenu', :partial => partial_path('menu')
          page.replace_html 'targetpanel', :partial => partial_path('console')
        end
      end
    else
      render :update do |page|
        page.alert('not implemented')
      end
    end
  end

  def restore_zip
    Zipfile.logger ||= logger
    @zipfile = Zipfile.new
        
    def zip_file(file)
      if (l = file.log_for_snapshot(@snapshot)) && l.event != 'D'
        @zipfile.add_file(:filename => file.filename,
          :path => file.path,
          :type => l.file_type,
          :extra => l.extra,
          :storage => Proc.new {l.storage})
        if l.file_type == 'D'
          file.children.each do |c|
            zip_file(c)
          end
        end
      end
    end
        
    selected = @tsession[:browse_server].all_selected
    selected.each do |f|
      if file = @target.files.find(f.id)
        zip_file(file)
      end
    end
    
    send_zipfile(@zipfile, :filename => 'myzip.zip')
  end

  def settings_browser_refresh_file
    item_id = params[:tree_item_id]

    item = @tsession[:settings_browser_root].find_by_id(item_id)
    
    worker = MiddleMan.worker(item.job_key)
    if worker && item
      if worker.results[:loaded]
        worker.results[:children].each do |c|
          klass = (c[:type] == 'D') ? FilesystemSettingsTree::Directory : FilesystemSettingsTree::File
          partial_name = (c[:type] == 'D') ? 'browse_directory' : 'browse_file'
          
          dir = @target.files.find(item.file_id)
          unless file = @target.files.find_by_parent_id_and_filename(item.file_id, c[:filename])
            file = Restore::Modules::Filesystem::File.create(
              :filename => c[:filename],
              :path => item.path+"/"+c[:filename],
              :target_id => @target.id,
              :parent_id => item.file_id,
              :included => nil
            )
          end
          
          selected = file.nil? ? item.selected : file.included?
          item << klass.new(nil, {
            :name => c[:filename],
            :selected => selected,
            :file_id => file.nil? ? nil : file.id,
            :file_type => c[:type],
            :target_id => @target.id,
            :partial_name => "settings_"+partial_name,
            :session_id => session.session_id,
            :target_options => @target.attributes,
            :target_class => @target.class,
            :size => c[:size],
            :mtime => c[:mtime],
            :path => item.path+"/"+c[:filename]})
        end
        item.loaded = true
      elsif worker.results[:error]
        item.error = worker.results[:error]
      end
      worker.delete
    end

    render :update do |page|
      if item.loaded
        page.replace item.full_id, :partial => partial_path(item.partial_name), :locals => {:item => item}
        item.children_values.reverse.each do |c|
          page.insert_html :after, item.full_id, :partial => partial_path(c.partial_name), :locals => {:item => c}
        end
      elsif item.error
        page.replace item.full_id, :partial => partial_path(item.partial_name), :locals => {:item => item}        
      end

    end # render
  end


  protected
  def setup_panel
    super
    case @tsession[:panel]
    when 'browse'
      @tsession[:browse_server] ||= FilesystemTargetTree::Server.new(@target, @snapshot)
    when 'settings'
      setup_settings_browser
    end
  end

  def setup_settings_browser
    @tsession[:settings_browser_root] = FilesystemSettingsTree::Directory.new(
    'settings_browser',
    :name => @target.root_name,
    :file_type => 'D',
    :selected => @target.root_directory.included?,
    :file_id => @target.root_directory.id,
    :target_id => @target.id,
    :partial_name => 'settings_browse_server',
    :expanded => false,
    :path => '',
    :target_class => @target.class,
    :session_id => session.session_id,
    :target_options => @target.attributes)
  end

  def update_target_options
    super
    setup_settings_browser
  end

  def find_tree(id)
    if id == 'settings_browser'
      @tsession[:settings_browser_root]
    elsif id == 'server'
      @tsession[:browse_server]
    end
  end

  def send_zipfile(zipfile, options = {}) #:doc:
    options[:type] = 'application/zip'
    
    disposition = 'attachment'
    disposition <<= %(; filename="#{options[:filename]}") if options[:filename]

    headers.update(
      'Content-Type'              => options[:type].strip,  # fixes a problem with extra '\r' with some browsers
      'Content-Disposition'       => disposition,
      'Content-Transfer-Encoding' => 'binary'
    )

    headers['Cache-Control'] = 'private' if headers['Cache-Control'] == 'no-cache'
    
    @performed_render = false

    render :status => options[:status], :text => Proc.new { |response, output|
      logger.info "Streaming zipfile" unless logger.nil?
      len = options[:buffer_size] || 4096
      
      loop do
        b = zipfile.read(len)
        if b.nil?
          break
        else
          output.write b
        end
      end
    }
  end
  


end
