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

class Wizard::BaseController < InstallationController

  @@steps = ['finalize']

  cattr_accessor :steps

  before_filter :load_session
  after_filter :save_session

  after_filter :post_render_step, :only => [:index, :show_step]
  
  private
  # setup auxiliary paths for these modules
  def initialize_template_class(response)
    super
    klass = self.class
    while klass && klass != Wizard::BaseController
      if klass.to_s.underscore =~ /\/(\w+)_controller$/
        response.template.aux_paths ||= []
        response.template.aux_paths << "#{RESTORE_ROOT}/modules/#{$1}/views"
      end
      klass = klass.superclass
    end
  end
  
  public
  def index
    setup_step(nil, 0)
    if request.xhr?
      render :update do |page|
        page.replace_html 'appcontent', :partial => partial_path('step')
      end
    else
      render '/wizard/index'
    end
  end

  def cancel
    render :update do |page|
      page << remote_function(:url => {:controller => '/targets', :action => :index})
    end
  end

  def show_step
    from_step = params[:this_step].to_i
    to_step = params[:step].to_i

    if (to_step == 0) && (from_step == (@@steps.size-1))
      # save it
      @success = true
      process_step_input(from_step, nil)

      setup_step(nil, from_step) unless @success
      Juggernaut.send_data("refresh_targets();", [:targets]) if @success

      render :update do |page|
        if @success
          #page << remote_function(:url => {:controller => '/targets', :action => :index})
          page << remote_function(:url => {:controller => "/target/#{@target[:type].underscore}", :id => @target.id})
        else
          page.replace_html 'appcontent', :partial => partial_path('step')
        end
      end
    else
      if from_step < to_step
        process_step_input(from_step, to_step)
      end
      setup_step(from_step, to_step)

      render :update do |page|
        page.replace_html 'appcontent', :partial => partial_path('step')
      end    
    end
  end

  protected  
  def init_session
    options = {}
    options[:client_id] = @current_client.id if dc_edition?
    session[:wizard] = { :target => self.class.target_class.new(options) }    
    @wsession = session[:wizard]
  end

  def load_session
    if params[:action] == 'index'
      init_session
    else
      @wsession = session[:wizard]
    end
    @target = @wsession[:target]
  end

  def save_session
  end

  def setup_step(from, to)
    @step = to.to_i
    if @step == (self.class.steps.size() - 1)
      # final step
      @prev_step = @step - 1
    elsif @step == 0
      # first step
      @next_step = 1
    else
      @next_step = @step + 1
      @prev_step = @step - 1
    end
    @step_partial = self.class.steps[@step]
    @step_num = to.to_i+2
  end

  def post_render_step
  end

  def process_step_input(from, to)
    case steps[from]
    when 'finalize'
      @target.name = params[:target][:name]
      @target.owner_id = @current_user.id
      @success = @target.save
    end
  end
end