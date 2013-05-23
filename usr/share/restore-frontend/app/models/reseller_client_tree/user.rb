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

module ResellerClientTree
  class User < ::TreeItem
    attr_reader :user
    
    def initialize(user)
      @user_id = user.id
      super("#{user.id}", :name => user.name, :partial_name => 'list_user')
    end

    def user
      Restore::Account::User.find(@user_id)
    end


    def client
      user.client
    end

  end
end