class AddContainerToObjectLog < ActiveRecord::Migration
  def self.up
    add_column :agent_object_logs, :container, :boolean, :default => false
  end
  
  def self.down
    remove_column :agent_object_logs, :container
  end
end
