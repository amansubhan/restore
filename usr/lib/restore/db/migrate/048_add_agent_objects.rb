class AddAgentObjects < ActiveRecord::Migration
  def self.up
    create_table :agent_objects do |t|
      t.column "target_id", :integer
      t.column "parent_id", :integer, :limit => 20
      t.column "type", :string
      t.column "name",  :text
      #t.column "path",  :text
      t.column "included",  :boolean
      t.column "extra",     :text
    end
    #add_index "filesystem_files", ["parent_id"], :name => "parent_id"
    #add_index "filesystem_files", ["target_id", "parent_id", "filename"], :name => "parent_filenames"  end
  end
  
  def self.down
    drop_table :agent_objects
  end
end
