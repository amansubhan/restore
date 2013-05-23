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
  module Snapper

    module_require_dependency :filesystem, 'snapper'
    require 'net/ftp'
    class Ftp < Restore::Snapper::Filesystem
      def run
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

      def copy_file(log)
        super
        begin
          attrs = {
            :btime => Time.now,
            :remote_size => 0 }
          if log.file_type == 'F'
            size = 0
            log.storage.open('w') do |local|
              @ftp.retrbinary("RETR " + log.file.path, 64.kilobytes) do |data|
                local.write data
                size += data.length
              end
            end
            
            attrs[:remote_size] = size
            attrs[:local_size] = log.storage.size
          end
        end

        return attrs
      end

      def read_directory(dir)
        begin
          @ftp.chdir(dir.path) unless dir.path.empty?
          
          @ftp.nlst.each do |file|
            file == '.' and next
            file == '..' and next
            yield file
          end
        rescue => e
          raise  unless e.to_s =~ /^226 Transfer complete.$/
        end
      end

      def make_attrs(parent_path, filename)
        pwd = @ftp.pwd
        type = 'D'
        mtime = nil
        size = nil
        begin
          @ftp.chdir("#{parent_path}/#{filename}") unless filename.empty?
        rescue => e
          if e.to_s =~ /Not a directory$/ || e.to_s =~ /^550/
            type = 'F'
            size = @ftp.size("#{parent_path}/#{filename}")
            mtime = @ftp.mtime("#{parent_path}/#{filename}")
          elsif e.to_s =~ /Permission denied$/
            raise "Permission denied"
          else
            raise
          end
        ensure
          @ftp.chdir pwd
        end
        return {
          :filename => filename,
          :type => type,
          :size => size,
          :mtime => mtime
        }        
      end
    end
  end
end
