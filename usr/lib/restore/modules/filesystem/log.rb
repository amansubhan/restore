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
  module Modules
    module Filesystem
      class Log < ActiveRecord::Base
        set_table_name 'filesystem_logs'
        
        belongs_to :file, :foreign_key => 'file_id'
        belongs_to :snapshot, :class_name => 'Restore::Snapshot::Base', :foreign_key => 'snapshot_id'
        belongs_to :target, :class_name => 'Restore::Target::Base', :foreign_key => 'target_id'
        
        serialize :extra, Hash
                
        def before_create
          self.target_id = target.id if target
        end
        
        
        cattr_accessor :file_handles      
        class << self
          @@file_handles ||= {}
        end

        def storage
          self.class.file_handles[self.id] ||= snapshot.storage.get_file_handle(file.path)
        end
       
        def prune
          removed = 0
          begin
            storage.unlink
            removed = local_size rescue 0
            update_attributes(:pruned => true, :extra => nil, :local_size => 0)
          rescue Errno::ENOTEMPTY
            # pass silently
          rescue => e
            logger.info e.to_s
          end
          snapshot.update_attributes(:local_size => (snapshot.local_size - removed))
        end

      end
    end
  end
end
