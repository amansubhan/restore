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
  class Client < ::TreeItem
    def initialize(client)
      @client_id = client.id
      super(client.id.to_s, :name => client.name, :partial_name => 'list_client')
      self << ClientUsers.new(client)
      self << ClientGroups.new(client)
      self << ClientTargets.new(client)
    end

    def client
      Restore::Client.find(@client_id)
    end

    def load_children
      
    end
    
    def children_values
      # our own sorting
      [@children['users'], @children['groups'], @children['targets']]
    end
    

    def refresh
      load_children
      @children.each_pair do |id,c|
        c.refresh
      end
    end
    
  end

  class ClientUsers < ::TreeItem
    def initialize(client)
      @client_id = client.id
      super('users', :name => _('Users'), :partial_name => 'list_clientusers', :expanded => true)
    end
    def client
      Restore::Client.find(@client_id)
    end

    def load_children
      @children ||= {}
      @children.delete_if {|id,c| !client.user_ids.include?(id.to_i) }
      
      client.users.each do |user|
        unless c = @children["#{user.id}"]
          self << User.new(user)
        end
      end
    end

    def refresh
      load_children
    end    
  end

  class ClientGroups < ::TreeItem
    def initialize(client)
      @client_id = client.id
      super('groups', :name => _('Groups'), :partial_name => 'list_clientgroups', :expanded => true)
    end

    def client
      Restore::Client.find(@client_id)
    end

    def load_children
      @children ||= {}
      @children.delete_if {|id,c| !client.group_ids.include?(id.to_i) }
      
      client.groups.each do |group|
        unless c = @children["#{group.id}"]
          self << Group.new(group)
        end
      end
    end

    def refresh
      load_children
    end    
  end

  class ClientTargets < ::TreeItem
    def initialize(client)
      @client_id = client.id
      super('targets', :name => _('Targets'), :partial_name => 'list_clienttargets', :expanded => true)
    end

    def client
      Restore::Client.find(@client_id)
    end

    def load_children
      @children ||= {}
      @children.delete_if {|id,c| !client.target_ids.include?(id.to_i) }
      
      client.targets.each do |target|
        unless c = @children["#{target.id}"]
          self << Target.new(target)
        end
      end
    end

    def refresh
      load_children
    end    
  end
end