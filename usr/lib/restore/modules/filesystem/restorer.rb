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
    require 'restore/restorer'
    
    class Filesystem < Restore::Restorer::Base
      
      def initialize(target, snapshot, logger, args)
        super
        @subdir = args[:subdir]
        @file_ids = args[:file_ids]
        
      end
      
      def execute
        super
        create_directory(@subdir) unless @subdir.empty?
        
        @copied = {}
        @file_ids.each do |id|
          if file = target.files.find(id)
            restore_file(file)
          end
        end

      end

      protected
      def restore_file(file)
        return if @copied[file.path]
        
        if (log = file.log_for_snapshot(snapshot)) && log.event != 'D' && log.btime && !log.pruned
          logger.info "Restoring #{file.path}"
          
          begin
            copy_file(file, log)
          rescue => e
            logger.info e.to_s
            #logger.info e.backtrace.join("\n")
          end
          @copied[file.path] = true
          
          if log.file_type == 'D'
            file.children.each do |c|
              restore_file(c)
            end
          end
        end
      end
      
      def create_directory(path)
        
      end
      
      def copy_file(file, log)
        
      end
      
    end
  end
end
