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


class DavResource::Client < DavResource::Base

  def initialize(href, user)
    super(nil)
    @user = user
    @href = href
    
    if dc_edition?
      @current_install = @user.installation
    else
      @current_install = Restore::Installation::Enterprise.new
    end
    
  end
  def collection?
    return true
  end

  def children
    @current_install.targets_for_user(@user).map {|t|
      t.dav_resource_class.new(self, t)
    }
  end

  def getcontentlength 
    0
  end

  def getcontenttype
    "httpd/unix-directory"
  end

  def properties
    [:displayname, :creationdate, :getlastmodified, :getcontenttype, :getcontentlength]
  end

  def displayname
    "/"
  end

  def href
    @href
  end

  def creationdate
    Date.today
  end

  def getlastmodified
  end

  def set_getlastmodified(value)
    gen_status(409, "Conflict").to_s
  end

  def getetag
  end

  def data
  end

  def get_resource_for_path(path)
    target_name = path[0]
    if target_name && (target = @current_install.target_by_name(target_name)) && (@user.can_read_target?(target))
      dr = target.dav_resource_class.new(self, target)
      if path[1..-1].empty?
        return dr
      else
        return dr.get_resource_for_path(path[1..-1])
      end
    end
  end
end
