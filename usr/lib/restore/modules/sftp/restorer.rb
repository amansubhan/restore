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
    class Sftp < Restore::Restorer::Filesystem
      require 'net/ssh'
      require 'net/sftp'
      include GetText
      bindtextdomain("restore")
      
      def execute
        @target.setup_keys do |key_path|
          begin
            Net::SFTP.start( @target.hostname, @target.port, @target.username, :paranoid => false, :keys => [key_path] ) do |@sftp|
              super
            end
          rescue => e
            if e.class == Net::SSH::AuthenticationFailed
              raise _("Authentication failed")
            else
              raise e.message
            end
          end
        end
      end

      def create_directory(path)
        stack = []
        until path == stack.last   # dirname("/")=="/", dirname("C:/")=="C:/"
          stack.push path
          path = File.dirname(path)
        end
      
        stack.reverse_each do |path|
          begin
            @sftp.mkdir(path, {})
          rescue Net::SFTP::Operations::StatusException => e
            logger.error(e.description) unless directory?(path)
          end
        end
      end
      
      def directory?(path)
        (@sftp.stat(path).permissions & 040000) == 040000
      rescue
        false
      end
      
      def copy_file(file, log)
        # XXX apply mtime!
        if log.file_type == 'D'
          create_directory(File.join(@subdir,file.path))
          begin
            @sftp.setstat(File.join(@subdir,file.path), :permissions => log.extra[:mode], :uid => log.extra[:uid], :gid => log.extra[:gid])
          rescue
            # silent
          end
        elsif log.file_type == 'F'
          create_directory(File.dirname(File.join(@subdir,file.path)))
          
          chunk_size = 64.kilobytes
          log.storage.open('r') do |local|
            begin
              @sftp.open_handle(File.join(@subdir,file.path), "w") do |handle|
                while data = local.read(chunk_size)
                  result = @sftp.write(handle, data)
                end
              end
            rescue Net::SFTP::Operations::StatusException => e
              logger.error e.description
            end
          end
          
          begin
            @sftp.setstat(File.join(@subdir,file.path), :permissions => log.extra[:mode], :uid => log.extra[:uid], :gid => log.extra[:gid])
          rescue
            # silent
          end
          
        elsif log.file_type == 'L'
          create_directory(File.dirname(File.join(@subdir,file.path)))
          begin
            @sftp.symlink(log.extra[:readlink], File.join(@subdir,file.path))
          rescue
            # silent
          end
        end


      end
    end
  end
end
