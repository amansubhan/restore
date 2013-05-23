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
  class Target < ::TreeItem
    
    def initialize(target)
      @target_id = target.id
      super("#{target.id}", :name => target.name, :partial_name => 'list_target')
    end

    def target
      Restore::Target::Base.find(@target_id)
    end

    def client
      target.client
    end

    

  end
end