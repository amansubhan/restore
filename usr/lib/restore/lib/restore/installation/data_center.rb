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

require 'restore/installation/base'
class Restore::Installation::DataCenter < Restore::Installation::Base
  attr_reader :client
  
  def initialize(client)
    @client = client
  end
  
  def size
    client.size
  end

  def quota
    client.quota
  end

  def space_percentage
    client.space_percentage
  end

  def available_space
    client.available_space
  end

  def targets
    client.targets
  end
  
  def target_by_name(name)
    client.targets.find_by_name(name)
  end
  
  def users
    client.users
  end
  
  def find_user(id)
    client.users.find(id)
  end

  def build_user(options={})
    client.users.build(options)
  end
  
  def groups
    client.groups
  end

  def find_group(id)
    client.groups.find(id)
  end

  def build_group(options={})
    client.groups.build(options)
  end

  def accounts
    users + groups
  end
  
  def account(id)
    client.accounts.find(id)
  end

end

class Object
  def dc_edition?
    true
  end  
  def e_edition?
    false
  end
end

