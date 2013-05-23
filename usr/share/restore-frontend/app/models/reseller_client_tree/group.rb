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
  class Group < ::TreeItem
    
    attr_reader :group
    
    def initialize(group)
      @group_id = group.id
      super("#{group.id}", :name => group.name, :partial_name => 'list_group')
    end

    def group
      Restore::Account::Group.find(@group_id)
    end

    def client
      group.client
    end

  end
end