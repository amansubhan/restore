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

require File.join(RESTORE_ROOT, 'config', 'boot')  

require 'fileutils'
switch_user

id = ARGV[1]

def clone_file(file, parent_dir, new_target)
  puts file.path
  new_file = file.clone
  if parent_dir
    new_file.parent_id = parent_dir.id
  else
    new_file.parent_id = nil
  end
  new_file.target_id = new_target.id
  new_file.save

  file.logs.each do |l|
    new_log = l.clone
    new_log.snapshot_id = @snapshot_translation[l.snapshot_id]
    new_log.file_id = new_file.id
    new_log.save
    if new_log.local_size && !new_log.pruned && new_log.btime
      begin
        FileUtils.cp l.local_path, new_log.local_path
      rescue
        puts $!.to_s
      end
    end
  end
  
  file.children.each do |c|
    clone_file(c, new_file, new_target)
  end
end

if target = Restore::Target::Base.find(id)
  new_target = target.clone
  i = 1
  loop do
    break unless Restore::Target::Base.find_by_name("#{target.name} (#{i})")
    i += 1
  end
  
  new_target.name = "#{target.name} (#{i})"
  new_target.save
  
  
  @snapshot_translation = {}
  target.snapshots.each do |s|
    new_snapshot = s.clone
    new_snapshot.target_id = new_target.id
    new_snapshot.save
    
    FileUtils::mkdir_p new_snapshot.repo_path
    
    @snapshot_translation[s.id] = new_snapshot.id
  end

  clone_file(target.root_directory, nil, new_target)
  
end
