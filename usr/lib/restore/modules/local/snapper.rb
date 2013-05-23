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
    class Local < Restore::Snapper::Filesystem

      protected
      def copy_file(log)
        super
        path = log.file.path
        path = '/' if path.empty?

        stat = File.lstat(path)
        extra = {
          :atime => stat.atime,
          :ctime => stat.ctime,
          :uid => stat.uid,
          :gid => stat.gid,
          :mode => stat.mode,
          :dev_minor => stat.dev_minor,
          :dev_major => stat.dev_major,
          :rdev_minor => stat.rdev_minor,
          :rdev_major => stat.rdev_major,
        }
        attrs = {
          :mtime => stat.mtime,
          :btime => Time.now,
          :remote_size => 0
        }
        
        begin
          if log.file_type == 'F'
            log.storage.open('w') do |local|
              File.open(File.join(path), 'r') do |remote|
                while data = remote.read(64.kilobytes)
                  local.write data
                end
              end
            end
            attrs[:remote_size] = File.stat(path).size
            attrs[:local_size] = log.storage.size
          elsif log.file_type == 'L'
            extra.merge!(:readlink => File.readlink(path))
          end
          attrs[:extra] = extra
        rescue Errno::EACCES
          raise _('Permission denied')
        end
        return attrs
      end

      def read_directory(dir, &block)
        Dir.open(dir.path+'/') do |d|
          d.each do |f|
            f == '.' and next
            f == '..' and next
            begin
               yield f
            rescue
              logger.error $!.to_s
            end
          end
        end
      rescue Errno::EACCES 
        logger.info _("Permission denied")
      end

      def make_attrs(parent_path, filename)
        stat = File.lstat("#{parent_path}/#{filename}")
        return {
          :filename => filename,
          :type => parse_type(stat.mode),
          :mtime => stat.mtime,
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
