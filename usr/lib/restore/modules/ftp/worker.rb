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
    require 'net/ftp'
    module_require_dependency :filesystem, 'worker'
    
    class Ftp < Restore::Worker::Filesystem

      class << self
        def list_directory(path, target_options)
          children = []
          
          ftp = Net::FTP.new
          
          ftp.passive = target_options["extra"][:passive]
          ftp.connect(target_options['hostname'], target_options['extra'][:port])
          ftp.login(target_options['username'], target_options['password'])
          
          if target_options["extra"][:homedir]
            ftp.chdir("./"+path)
          else
            ftp.chdir('/'+path)
          end
          pwd = ftp.pwd
          
          begin
            ftp.nlst.each do |file|
              file == '.' and next
              file == '..' and next
            
              type = 'D'
              mtime = nil
              size = nil
              begin
                ftp.chdir file
              rescue
                type = 'F'
                if $!.to_s =~ /Not a directory$/
                  type = 'F'
                  size = ftp.size(file)
                  mtime = ftp.mtime(file)
                end
              ensure
                ftp.chdir pwd
              end
              children << {
                :filename => file,
                :type => type,
                :size => size,
                :mtime => mtime
              }
            end
          rescue
             raise unless $!.to_s =~ /^226/ # Transfer complete
          end
          ftp.close
          return {:children => children, :loaded => true}
        end # def list_directory

      end # class << self
    end # class Ftp
  end # module Browser
end # module Restore