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



class DavResource::Root
   include WebDavResource
   attr_accessor :href
   
   def initialize(path, user)
     @href, @user = path, user
   end
   def collection?
     return true
   end

   def children
     return @user.targets.find(:all).map {|t|
       t.dav_resource_class.new(t, File.join(@href,CGI.escape(t.name)))
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
   
   def creationdate
     #puts "targetlist creationdate()"
     Date.today
   end
   
   def getlastmodified
     #puts "targetlist getlastmodified()"
   end
   
   def set_getlastmodified(value)
     #puts "targetlist set_getlastmodified()"
     gen_status(409, "Conflict").to_s
   end
   
   def getetag
     #puts "targetlist getetag()"
   end
         
   def data
     #puts "targetlist data()"
   end
   

end
