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


class DavResource::Base
  include WebDavResource
  attr_accessor :parent
  attr_accessor :name
   
  def initialize(parent)
    @parent = parent
  end
     
  def href
    href = parent ? parent.href : ''
    href = ::File.join(href, CGI.escape(displayname)) + (collection? ? '/' : '')
    href
  end

end
