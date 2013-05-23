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
    module_require_dependency :filesystem, 'target'
    
    class Ftp < Restore::Target::Filesystem
      # FRONTEND
      # create a human friendly name for the root of the target
      def root_name
        "ftp://#{self.username}@#{self.hostname}#{self.port==21?'':self.port}"
      end
      
      def homedir
        self.extra ||= {}
        self.extra[:homedir] ? true : false      
      end
      
      def homedir=(value)
        self.extra ||= {}
        self.extra[:homedir] = (value == "1" ? true : false)
      end

      def passive
        self.extra ||= {}
        self.extra[:passive] ? true : false      
      end
      
      def passive=(value)
        self.extra ||= {}
        self.extra[:passive] = (value == "1" ? true : false)
      end

      def port
        self.extra ||= {}
        self.extra[:port] ||= 21
      end
      
      def port=(val)
        self.extra ||= {}
        self.extra[:port] = val.to_i
      end

    end
  end
end
