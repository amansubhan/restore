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
  module Worker
    module_require_dependency :filesystem, 'worker'
    
    class Samba < Restore::Worker::Filesystem
      include GetText
      bindtextdomain("restore")
      
      class << self
        def list_directory(path, target_options)
          require 'smb'
          url = "smb://#{target_options['username']}:#{target_options['password']}@#{target_options['hostname']}#{path}"
          begin
            children = []
            SMB::Dir.open url do |d|
              d.each do |f|
                f == '.' and next
                f == '..' and next
                file = {:filename => f}
                begin
                  smbfile = SMB.open(url+'/'+f)
                  stat = SMB.stat(url+'/'+f)
                  file[:type] = (smbfile.class == SMB::File) ? 'F' : 'D'
                  file[:size] = (smbfile.class == SMB::File) ? stat.size : nil
                  file[:mtime] = stat.mtime
                rescue Errno::EACCES => e
                  logger.info 'Permission denied'
                  file[:error] = 'Permission denied'
                rescue => e
                  logger.info e.to_s
                  file[:error] = e.to_s
                end
                children << file                
              end # d.each
            end # Dir.open
            return {:children => children, :loaded => true}
          rescue Errno::ECONNREFUSED
            raise _('Connection refused')
          end # begin
        end # def list_directory
      end
    end # class Samba
  end # module Worker
end # module Restore