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
  class Root < ::TreeItem

    def initialize(reseller)
      @reseller_id = reseller.id
      super('reseller', :partial_name => 'list_reseller', :expanded => true)
    end


    def load_children
       
      @children ||= {}
      @children.delete_if {|id,c| !reseller.client_ids.include?(id.to_i) }
      
      reseller.clients.each do |client|
        unless c = @children[client.id.to_s]
          self << Client.new(client)          
        end
      end
    end
    
    def refresh
      load_children
      @children.each_pair do |id,c|
        c.refresh
      end
    end
    
    def reseller
      Restore::Account::Reseller.find(@reseller_id)
    end
        
  end
end