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

module MysqlTargetTree
  class Server < ::TreeItem


    def initialize(target, snapshot)
      @target = target # XXX don't save these!  save the IDs!
      @snapshot = snapshot
      super('server',
        :name => "mysql://#{@target.username}@#{@target.hostname}/",
        :partial_name => 'browse_server',
        :expanded => true)
        
    end

    def load_children
      @children ||= {}
      @target.databases.each do |database|
        if (l = database.log_for_snapshot(@snapshot)) && l.event != 'D'
          if c = @children[database.id.to_s]
            c.set_snapshot(@snapshot)
          else  
            self << Database.new(database, @snapshot, l)
          end
        else
          @children.delete(database.id.to_s)
        end
      end
    end
    

    def set_snapshot(snapshot)
      @snapshot = snapshot
      if expanded
        load_children
      end
    end

  end
end