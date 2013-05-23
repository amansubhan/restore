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
  
  module_require_dependency :filesystem, 'worker'
    
  class Sftp < Restore::Worker::Filesystem
    require 'net/ssh'
    require 'net/sftp'

    class << self
      
      # install the public ssh key on the server
      def install_key(hostname, port, username, password, pubkey)
        err = nil
        Net::SSH.start( hostname, port, username, password, :paranoid => false) do |session|
          shell = session.shell.open
          shell.mkdir "-p ~/.ssh"
          shell.echo "-n '#{pubkey}' >> ~/.ssh/authorized_keys2"
          shell.exit

          # give the above commands sufficient time to terminate
          sleep 0.5
          #err = shell.stderr if shell.stderr? && shell.stderr != "stdin: is not a tty\n"
        end
        raise err unless err.nil?
        return {:installed => true}
      end
      
      # get a directory listing.
      def list_directory(path, target_options)
        children = []
        begin
          if target_options['password']
            Net::SFTP.start(target_options['hostname'], target_options['extra'][:port].to_i, target_options['username'], target_options['password'], :paranoid => false) do |sftp|
              children = list_directory2(sftp, path)
            end
          else 
            setup_keys(target_options['extra'][:key], target_options['extra'][:pubkey]) do |key_path|
              Net::SFTP.start(target_options['hostname'], target_options['extra'][:port].to_i, target_options['username'], :paranoid => false, :keys => [key_path]) do |sftp|
                children = list_directory2(sftp, path)
              end
            end
          end
        rescue Net::SSH::AuthenticationFailed => e
          raise "Authentication failed"
        end

        return {:children => children, :loaded => true}
      end # def list_directory

      protected
      def setup_keys(key, pubkey, &block)
        t = Tempfile.new('id_rsa')
        t.write key
        t.close

        pub = t.path+".pub"
        File.open(pub, "w") do |f|
          f.write pubkey
        end

        begin
          yield t.path
        ensure
          t.unlink
          File.unlink(pub)
        end
      end
      
      def list_directory2(sftp, path)
        children = []
        handle = sftp.opendir('/'+path)
        sftp.readdir(handle).each do |f|
          f.filename == '.' and next
          f.filename == '..' and next
          stat = sftp.lstat("#{path}/#{f.filename}")
          #logger.info "#{path}/#{f.filename}"
          #logger.info stat.mtime.inspect
          mtime = Time.at(stat.mtime) rescue nil
          children << {
            :filename => f.filename,
            :type => parse_type(stat.permissions),
            :size => stat.size,
            :mtime => mtime
          }
        end
        return children
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
    end # class << self
  end # class Sftp
end # module Restore::Worker