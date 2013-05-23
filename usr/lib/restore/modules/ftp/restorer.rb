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
    require 'net/ftp'
    class Ftp < Restore::Restorer::Filesystem
      
      def execute
        @ftp = Net::FTP::new
        @ftp.passive = @target.passive
        @ftp.connect(@target.hostname, @target.port)
        @ftp.login(@target.username, @target.password)
        
        begin
          super
        ensure
          @ftp.close
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
            @ftp.mkdir(path)
          rescue => e 
            raise unless directory?(path) || e.to_s =~ /File exists/
          end
        end
      end
      
      def directory?(path)
        pwd = @ftp.pwd
        @ftp.chdir(path)
      rescue => e
        false if e.to_s =~ /Not a directory$/
      ensure
        @ftp.chdir pwd
      end
      
      def copy_file(file, log)
        # XXX apply mtime!
        if log.file_type == 'D'
          create_directory(File.join(@subdir,file.path))
        elsif log.file_type == 'F'
          create_directory(File.dirname(File.join(@subdir,file.path)))
          log.storage.open('r') do |local|
            @ftp.storbinary("STOR " + File.join(@subdir,file.path), local, 64.kilobytes)
          end
        end
      end
    end
  end
end
