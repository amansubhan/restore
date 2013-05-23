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
    class Samba < Restore::Snapper::Filesystem
      require 'smb'
      
      def copy_file(log)
        super
        stat = SMB.stat(File.join(@target.base_url, log.file.path))
        extra = {}
        attrs = {
          :mtime => stat.ctime,
          :btime => Time.now,
          :remote_size => 0,
        }
        
        if log.file_type == 'F'
          log.storage.open('w') do |local|
            SMB.open File.join(@target.base_url, log.file.path), "r" do |remote|
              begin
                #remote.listxattr.each do |name|
                  #at = remote.getxattr(name) rescue '';
                  #puts "#{name}: '#{at}'"
                #end
                while data = remote.read(1024)
                  local.write(data)
                end
              rescue => e
                logger.error $!.to_s
              end
            end
          end
          attrs[:remote_size] = stat.size
          attrs[:local_size] = log.storage.size
        end
        attrs.merge!(:extra => extra)
        return attrs
      end

      def read_directory(dir)
        SMB::Dir.open File.join(@target.base_url, dir.path) do |d|
          d.each do |f|
            f == '.' and next
            f == '..' and next
            begin
              yield f
            end
          end
        end
      end

      def make_attrs(parent_path, filename)
        begin
          smbfile = SMB.open(File.join(@target.base_url, parent_path, filename))          
          
          stat = SMB.stat(File.join(@target.base_url, parent_path, filename)) rescue nil
          mtime = stat.ctime rescue 0 # XXX what's this?  ctime?
          size = stat.size rescue 0
          
          type = (smbfile.class == SMB::File) ? 'F' : 'D'

          return {
            :filename => filename,
            :type => type,
            :mtime => mtime, 
            :size => size }
        rescue => e
          logger.error $!.to_s #+e.backtrace.join("\n")
          return {
            :filename => filename,
            :error => $! }
        end        
      end
    end
  end
end