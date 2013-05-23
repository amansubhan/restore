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


module Restore
  module Target
    class Samba < Restore::Target::Filesystem
      include GetText
      bindtextdomain("restore")
      
      # BACKEND
      def base_url
        "smb://#{username}:#{password}@#{hostname}"
      end

      # FRONTEND (maybe backend, with emails)
      def type_name
  	    _("Windows File Share")
  	  end

      # FRONTEND (maybe backend, with emails)  	  
  	  def root_name
        "smb://#{username}@#{hostname}/"
      end
      
      
    end
  end
end
