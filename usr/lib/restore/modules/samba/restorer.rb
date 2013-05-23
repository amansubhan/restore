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
    module_require_dependency :filesystem, 'restorer'
    require 'smb'
    
    class Samba < Restore::Restorer::Filesystem
      
      def create_directory(path)
        stack = []
        until path == stack.last   # dirname("/")=="/", dirname("C:/")=="C:/"
          stack.push path
          path = File.dirname(path)
        end
        # pop off the top level (server)
        stack.pop
        # pop off the second level (share)
        stack.pop
        stack.reverse_each do |path|
          begin
            SMB::Dir.mkdir(File.join(@target.base_url, path))
          rescue => e #Net::SFTP::Operations::StatusException => err
            raise unless directory?(path)
          end
        end
      end
      
      def directory?(path)
        (SMB.stat(File.join(@target.base_url, path)).mode & 040000) == 040000
      rescue
        false
      end
      
      def copy_file(file, log)
        # XXX restore perms!
        if log.file_type == 'D'
          create_directory(File.join(@subdir, file.path))
        elsif log.file_type == 'F'
          create_directory(File.dirname(File.join(@subdir, file.path)))
          
          SMB::File.delete(File.join(@target.base_url, @subdir, file.path))
          
          SMB.open File.join(@target.base_url, @subdir, file.path), "w" do |remote|
            log.storage.open('r') do |local|
              begin
                while data = local.read(1024)
                  remote.write(data)
                end
              rescue => e
                logger.error $!.to_s
              end
            end # File.open
          end # SMB.open
        end
      end
      
    end
  end
end
