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

module WebDavResource
  
  def self.logger=(logger)
    @@logger = logger
  end
  
  def logger
    @@logger
  end
end


class DavController < ActionController::Base
  act_as_railsdav
  
  protected
  def get_auth_data
    user, pass = '', ''

    [ 'REDIRECT_REDIRECT_X_HTTP_AUTHORIZATION',
    'REDIRECT_X_HTTP_AUTHORIZATION',
    'X-HTTP_AUTHORIZATION', 
    'HTTP_AUTHORIZATION'
    ].each do |key|
      if request.env.has_key?(key)
        authdata = request.env[key].to_s.split
        # at the moment we only support basic authentication 
        if authdata[0] == 'Basic'
          user, pass = Base64.decode64(authdata[1]).split(':')[0..1]
          break
        end
      end
    end         
    return [user, pass]
  end

  before_filter :user_auth
  def user_auth
    basic_auth_required {|username, password|
      password ||= ''
      true if (@current_user = Restore::Account::User.authenticate(username, password))
    }
  end
  
  protected
  def mkcol_for_path(path)
    logger.info 'mkcol_for_path'
    raise WebDavErrors::ForbiddenError
  end

  def write_content_to_path(path, content)
    logger.info 'write_content_to_path'
    raise WebDavErrors::ForbiddenError
  end
  
  def copy_to_path(resource, dest_path, depth)
    logger.info 'copy_to_path' 
    raise WebDavErrors::ForbiddenError
  end
  
  def move_to_path(resource, dest_path, depth)
     logger.info 'move_to_path'
     
     raise WebDavErrors::ForbiddenError
  end

  def get_resource_for_path(path)
    WebDavResource.logger = logger
    
    logger.info "get_resource_for_path(#{path})"
    if @current_user.class == Restore::Account::User
      dr = DavResource::Client.new(href_for_path('')+'/', @current_user)
    else
      raise WebDavErrors::ForbiddenError      
    end
    
    if path.blank? or path.eql?("/")
      return dr
    else
      return dr.get_resource_for_path(path.split('/'))
    end
  end
  
  def send_io(io, options = {}) #:doc:
    logger.info "Sending data #{options[:filename]}" unless logger.nil?
    #send_file_headers! options.merge(:length => '')
    disposition = 'attachment'
    disposition <<= %(; filename="#{options[:filename]}") if options[:filename]
    headers.update(
      # XXX get this back in there somehow?
      #'Content-Type'              => options[:type].strip,  # fixes a problem with extra '\r' with some browsers
      'Content-Disposition'       => disposition,
      'Content-Transfer-Encoding' => 'binary'
    )

    headers['Cache-Control'] = 'private' if headers['Cache-Control'] == 'no-cache'
    
    @performed_render = false
    render :status => options[:status], :text => Proc.new { |response, output|
      len = options[:buffer_size] || 4096
      loop do
        b = io.read(len)
        if b.nil?
          break
        else
          output.write b
        end
      end
    }
  end
  
end