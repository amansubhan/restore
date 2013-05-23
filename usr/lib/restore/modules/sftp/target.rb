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
  module Target
    class Sftp < Restore::Target::Filesystem
      require 'tempfile'

      # FRONTEND
      # take the password and store the public key on the target
      # with it
      def after_create
        create_key
        store_public_key(self.password)
        self.password = nil
        self.save
      end

      # FRONTEND
      # create a human friendly name for the root of the target
      def root_name
        "ssh://#{self.username}@#{self.hostname}#{self.port==22?'':':'+self.port}"
      end


      # FRONTEND
      # call on the backend to store the key on the server
      def store_public_key(password)
        job_key = self.class.new_worker(:install_key, [self.hostname, self.port, self.username, password, self.pubkey])
        worker = MiddleMan.worker(job_key)
        loop do
          break if worker.results[:completed]
        end
        ret = worker.results[:installed]
        worker.delete
        return ret
      end

      # BACKEND
      # create public/private SSH keys      
      def create_key
        self.extra ||= {}
        if !extra[:key]
          # kinda lame
          t = Tempfile.new('rd_rsa')
          path = t.path
          t.unlink
          
          system("ssh-keygen -t rsa -N '' -f #{path}")
          self.extra[:key] = File.read(path)
          self.extra[:pubkey] = File.read(path+'.pub')
          File.unlink(path)
          File.unlink(path+'.pub')
          save
        end
      end

      # BACKEND
      # run a block of code which has access to the public and private keys for this target.
      # the value passed to the block of code is the path to the public key
      def setup_keys(&block)
        t = Tempfile.new('id_rsa')
        t.write self.extra[:key]
        t.close
  
        pub = t.path+".pub"
        File.open(pub, "w") do |f|
          f.write self.extra[:pubkey]
        end
        
        begin
          yield t.path
        ensure
          t.unlink
          File.unlink(pub)
        end
      end
      
      def pubkey
        self.extra ||= {}
        self.extra[:pubkey]
      end

      def key
        self.extra ||= {}
        self.extra[:key]
      end

      def port
        self.extra ||= {}
        self.extra[:port] ||= 22
      end
      
      def port=(val)
        self.extra ||= {}
        self.extra[:port] = val.to_i
      end

    end
  end
end
