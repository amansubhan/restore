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

module Restore::Worker
  require 'fileutils'
  module_require_dependency :filesystem, 'worker'
    
  class Local < Restore::Worker::Filesystem
    class << self
      def list_directory(path, target_options=nil)
        children = []
        Dir.open('/'+path) do |d|
          d.each do |f|
            f == '.' and next
            f == '..' and next
            stat = ::File.lstat("#{path}/#{f}")
            children << {
              :filename => f,
              :type => parse_type(stat.mode),
              :size => stat.size,
              :mtime => stat.mtime
            }
          end
        end
        return {:children => children, :loaded => true}
      end
        
      protected
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