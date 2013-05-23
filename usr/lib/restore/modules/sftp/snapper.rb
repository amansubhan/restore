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
    class Sftp < Restore::Snapper::Filesystem
      require 'net/ssh'
      require 'net/sftp'
      include GetText
      bindtextdomain("restore")
      
      def run2
        ENV['SSH_AUTH_SOCK'] = nil
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
      
      def copy_file(log)
        super
        path = log.file.path
        path = '/' if path.empty?
        
        begin
          stat = @sftp.lstat(path)
          extra = {
            :atime => stat.atime,
            :uid => stat.uid,
            :gid => stat.gid,
            :mode => stat.permissions }
          attrs = {
            :mtime => Time.at(stat.mtime),
            :btime => Time.now,
            :remote_size => 0 }
          if log.file_type == 'F'
            log.storage.open('w') do |local|
              chunk_size = 64*1024
              @sftp.open_handle(path) do |h|
                offset = 0
                while data = @sftp.read( h, :offset => offset, :length => chunk_size )
                  break unless data.length > 0
                  offset += data.length
                  local.write(data)
                end
              end
            end
            attrs[:remote_size] = stat.size
            attrs[:local_size] = log.storage.size
          elsif log.file_type == 'L'
            extra.merge!(:readlink => @sftp.readlink(path).longname)
          end
          attrs[:extra] = extra

        rescue Net::SFTP::Operations::StatusException => e
          raise e.description
        end

        return attrs        
      end

      def read_directory(dir)
        begin
          handle = @sftp.opendir('/'+dir.path)
          @sftp.readdir(handle).each do |f|
            f.filename == '.' and next
            f.filename == '..' and next
            yield f.filename
            
          end
        rescue  Net::SFTP::Operations::StatusException => e
          logger.error e.description
        ensure
          @sftp.close_handle(handle) if handle
        end
      end

      def make_attrs(parent_path, filename)
        stat = @sftp.lstat("#{parent_path}/#{filename}")
        mtime = Time.at(stat.mtime)
        return {
          :filename => filename,
          :type => parse_type(stat.permissions),
          :mtime => mtime,
          :size => stat.size }        
      end


      def parse_type(perm)
        if((perm & 0140000) == 0140000) # socket
          return 'S'
        elsif((perm & 0120000) == 0120000) # symlink
          return 'L'
        elsif((perm & 0100000) == 0100000) # regular file
          return 'F'
        elsif((perm & 060000) == 060000) # block device
          return 'B'
        elsif((perm & 040000) == 040000) # directory
          return 'D'
        elsif((perm & 020000) == 020000) # character device
          return 'C'
        elsif((perm & 010000) == 010000) # fifo
          return 'I'
        end
        raise "could not determine file type"
      end

    end
  end
end
