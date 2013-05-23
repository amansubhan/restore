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


# XXX shouldn't this be in the frontend, and not the common lib?
module Restore
  module DavResource
    
    class Snapshot < ::DavResource::Base

      attr_reader :snapshot

      WEBDAV_PROPERTIES = [:displayname, :creationdate, :getcontenttype, :getcontentlength]

      def initialize(parent, s)
        super(parent)
        @snapshot = s
      end

      def collection?
        return true
      end

      def children
        []
      end

      def getcontenttype
        "httpd/unix-directory"
      end

      def properties
        WEBDAV_PROPERTIES
      end

      def displayname
        snapshot.id.to_s
      end

      def creationdate
        Date.today
      end

      def getcontentlength 
        0
      end
      
      def get_resource_for_path(path)
        raise WebDavErrors::ForbiddenError
      end      
      
    end
  end
end