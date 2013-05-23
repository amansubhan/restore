class AddRemoteSizeToMysql < ActiveRecord::Migration
  def self.up
    add_column :mysql_logs, :remote_size, :integer,  :limit => 20
    add_column :mysql_logs, :pruned, :boolean, :default => false
    
    change_column :filesystem_logs, :remote_size, :integer,  :limit => 20
  end

  def self.down
    remove_column :mysql_logs, :remote_size
    remove_column :mysql_logs, :pruned
  end
end
