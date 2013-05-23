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
    class Target < ::DavResource::Base
      attr_reader :target

      WEBDAV_PROPERTIES = [:displayname, :creationdate, :getcontenttype, :getcontentlength]


      def initialize(parent, t)
        super(parent)
        @target = t
      end

      def collection?
        return true
      end

      def children
        return target.full_snapshots.map {|s|
          s.dav_resource_class.new(self, s)
        }
      end

      def getcontenttype
        "httpd/unix-directory"
      end

      def properties
        WEBDAV_PROPERTIES
      end

      def displayname
        target.name
      end

      def creationdate
        Date.today
      end

      def getcontentlength
        0
      end
      
      def get_resource_for_path(path)
        
        snapshot_id = path[0].to_i
        if snapshot_id && (snapshot = target.snapshots.find(snapshot_id) rescue nil)
          dr = snapshot.dav_resource_class.new(self, snapshot)
          if path[1..-1].empty?
            return dr
          else
            return dr.get_resource_for_path(path[1..-1])
          end          
        end
      end
      
    end
  end
end