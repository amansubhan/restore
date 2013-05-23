class AddAgentObjectLog < ActiveRecord::Migration
  def self.up
    create_table :agent_object_logs do |t|
      t.column :object_id, :integer, :limit => 20
      t.column :snapshot_id, :integer, :limit => 20
      t.column :event, :string
      t.column :btime, :datetime
      t.column :error, :text
      t.column :local_size, :integer, :limit => 20
      t.column :extra, :text
    end
    #add_index "filesystem_files", ["parent_id"], :name => "parent_id"
    #add_index "filesystem_files", ["target_id", "parent_id", "filename"], :name => "parent_filenames"  end
  end
  
  def self.down
    drop_table :agent_object_logs
  end
end
