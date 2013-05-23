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

ActionController::Base.class_eval do
  def rescue_action(exception)
    log_error(exception) if logger
    erase_results if performed?
    if consider_all_requests_local || local_request?
      add_variables_to_assigns
      @template.instance_variable_set("@exception", exception)
      @template.instance_variable_set("@rescues_path", "#{template_root}/rescues/")
      @template.send(:assign_variables_from_controller)
      @template.instance_variable_set("@contents",
        @template.render_file(template_path_for_local_rescue(exception), false))
      headers["Content-Type"] = "text/html"

      msg = render_to_string :file => rescues_path("layout")
      if request.xhr?
        render :update do |page|
          page.replace_html 'error_message', @contents
          page << "$('error_window').style['display']='block';"
        end
      else
        render_file(rescues_path("layout"), response_code_for_rescue(exception))
      end
    else
      rescue_action_in_public(exception)
    end
  end
end

ActionController::CgiRequest.class_eval do 
  def stale_session_check!
    yield
  rescue ArgumentError => argument_error
    if argument_error.message =~ %r{undefined class/module ([\w:]+)}
      begin
        Module.const_missing($1.gsub(/::$/, ''))
      rescue LoadError, NameError => const_error
        raise ActionController::SessionRestoreError, <<-end_msg
Session contains objects whose class definition isn\'t available.
Remember to require the classes for all objects kept in the session.
(Original exception: #{const_error.message} [#{const_error.class}])
end_msg
      end
      retry
    else
      raise
    end
  end
end

ActionView::Helpers::PrototypeHelper.class_eval do
  alias_method :orig_remote_function, :remote_function
  def remote_function(options)
    unless options[:nowait]
      options[:loading] ||= "document.body.style.cursor='wait';"
      #Effect.Fade('flash');Effect.Appear('progress_indicator')"
      options[:complete] ||= "document.body.style.cursor='default';" #"Effect.Fade('progress_indicator');"
    end
    orig_remote_function(options) 
  end   
end

class ActionView::Base
  attr_accessor :aux_paths
  
  private
  # override to search additional paths for view inheritance
  def full_template_path(template_path, extension)
    @aux_paths ||= []
    @aux_paths.each do |p|
      return "#{p}/#{template_path}.#{extension}" if File.exist?("#{p}/#{template_path}.#{extension}")
    end
    return "#{@base_path}/#{template_path}.#{extension}"
  end
end

CGI::Session.class_eval do
  attr_accessor :data
end

module Railsdav
  module InstanceMethods
    alias_method :webdav_get_orig, :webdav_get
    
    def webdav_get
      resource = get_resource_for_path(@path_info)
      raise WebDavErrors::NotFoundError if resource.blank?
      data_to_send = resource.data 
      raise WebDavErrors::NotFoundError if data_to_send.blank?
      response.headers["Last-Modified"] = resource.getlastmodified
      
      if data_to_send.kind_of? File
        send_file File.expand_path(data_to_send.path), :filename => resource.displayname, :stream => true
      elsif data_to_send.respond_to?(:read)
        send_io data_to_send, :filename => resource.displayname
      else
        send_data data_to_send, :filename => resource.displayname unless data_to_send.nil?
      end 
    end
    
  end
end



