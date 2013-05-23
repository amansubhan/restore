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
  module Account
    class Base < ActiveRecord::Base
      set_table_name 'accounts'
      abstract_class = true

      validates_presence_of :name
      validates_uniqueness_of :name, :scope => :client_id

      attr_protected :id, :hashed_password
      attr_accessor :password, :password_confirmation
      validates_confirmation_of :password

      def password=(pass)
        @password=pass
        unless pass.empty?
          self.hashed_password = Digest::MD5.hexdigest pass
        end
      end

      def self.authenticate(username, password)
        find_by_name(username, :conditions => ["hashed_password = ?", Digest::MD5.hexdigest(password)])
      end

    end
  end
end