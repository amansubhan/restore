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

  module Restorer
    require 'fileutils'
    require 'gettext'
    
    class Base
      include GetText
      bindtextdomain("restore")
      
      attr_reader :target
      attr_reader :snapshot
      attr_reader :logger
      
      def initialize(target, snapshot, logger, args)
        @target, @snapshot, @logger, @args = target, snapshot, logger, args
      end

      def run
        logger.info _("Restore started at %s") % [Time.now]
        execute
        end_time = Time.now        
        logger.info _("Restore finished at %s") % [end_time]
      end
            
      def execute

      end
                  
    end
  end

end
