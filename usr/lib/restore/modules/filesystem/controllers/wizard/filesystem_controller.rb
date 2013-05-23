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


class Wizard::FilesystemController < Wizard::BaseController

  @@steps = ['browse', 'finalize']

  def refresh_file
    item_id = params[:id]

    item = @filesystem_wizard_root.find_by_id(item_id)
    worker = MiddleMan.worker(item.job_key)
    if worker && item
      if worker.results[:loaded]
        worker.results[:children].each do |c|
          klass = (c[:type] == 'D') ? FilesystemWizardTree::Directory : FilesystemWizardTree::File
          partial_name = (c[:type] == 'D') ? 'browse_directory' : 'browse_file'

          item << klass.new(nil, {
            :name => c[:filename],
            :file_type => c[:type],
            :partial_name => partial_name,
            :selected => item.selected,
            :session_id => session.session_id,
            :target_options => @target.attributes,
            :size => c[:size],
            :mtime => c[:mtime],
            :path => item.path+"/"+c[:filename],
            :error => c[:error],
            :target_class => @target.class})
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
  def init_session
    super
    @wsession.delete :browser_root
  end

  def load_session
    super
    if @wsession[:browser_root]
      @filesystem_wizard_root = @wsession[:browser_root]
    end
  end

  def save_session
    if @filesystem_wizard_root
      @wsession[:browser_root] = @filesystem_wizard_root
    end
  end


  def find_tree(id)
    if id == 'root'
      @filesystem_wizard_root
    end
  end

  def setup_step(from, to)
    super
    case self.class.steps[to]
    when 'browse'
      if from.nil? || from < to
        @filesystem_wizard_root = FilesystemWizardTree::Directory.new(
        'root',
        :name => @target.root_name,
        :file_type => 'D',
        :partial_name => 'browse_server',
        :expanded => false,
        :selected => true,
        :target_class => @target.class,
        :session_id => session.session_id,
        :target_options => @target.attributes,
        :path => ''
        )
      end
    end    
  end

  def post_render_step
    super
    #case self.class.steps[@step]
    #when 'browse'
    #  @filesystem_wizard_root.load_children
    #end
  end

  def process_step_input(from, to)
    case steps[from]
    when 'browse'

      file = Restore::Modules::Filesystem::File.new(
      :filename => '',
      :path => @filesystem_wizard_root.path,
      :target => @target,
      :included => @filesystem_wizard_root.selected
      )
      @target.files << file
      create_file_entries(@filesystem_wizard_root, file, @filesystem_wizard_root.selected)
    when 'finalize'
    end
    super
  end

  def create_file_entries(tree_item, restore_dir, parent_included)
    if tree_item.children
      tree_item.children_values.each do |c|
        #unless parent_included == c.selected
          file = Restore::Modules::Filesystem::File.new(
            :filename => c.name,
            :path => c.path,
            :target => @target,
            :parent => restore_dir,
            :included => c.selected
            )
          @target.files << file
          #restore_dir.children << file
        #end
        create_file_entries(c, file, c.selected)
      end
    end
  end
  
end
