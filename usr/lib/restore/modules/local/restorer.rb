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

require 'fileutils'
module Restore
  module Restorer
    module_require_dependency :filesystem, 'restorer'
    
    class Local < Restore::Restorer::Filesystem


      def create_directory(path)
        FileUtils.mkdir_p(path)        
      end
      
      def copy_file(file, log)
        if log.file_type == 'D'
          create_directory(File.join(@subdir,file.path))
          ::FileUtils.chmod(log.extra[:mode], File.join(@subdir,file.path))
          begin
            ::FileUtils.chown(log.extra[:uid].to_s, log.extra[:gid].to_s, File.join(@subdir,file.path))
          rescue
            # silent
          end
        elsif log.file_type == 'F'
          create_directory(File.dirname(File.join(@subdir,file.path)))
          log.storage.open("r") do |local|
            File.open(File.join(@subdir,file.path), 'w') do |remote|
              remote.write local.read
            end
          end

          ::FileUtils.chmod(log.extra[:mode], File.join(@subdir,file.path))
          begin
            ::FileUtils.chown(log.extra[:uid].to_s, log.extra[:gid].to_s, File.join(@subdir,file.path))
          rescue
            # silent
          end
        elsif log.file_type == 'L'
          create_directory(File.dirname(File.join(@subdir,file.path)))
          ::FileUtils.symlink(log.extra[:readlink], File.join(@subdir,file.path))
        end
      end

    end
  end
end
