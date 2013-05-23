class ForceBigInt < ActiveRecord::Migration
  def self.up
    change_column :accounts, :quota, :integer, :limit => 20
    change_column :clients, :quota, :integer, :limit => 20
    change_column :filesystem_files, :id, :integer, :limit => 20
    change_column :filesystem_logs, :id, :integer, :limit => 20
    change_column :filesystem_logs, :file_id, :integer, :limit => 20
    change_column :filesystem_logs, :local_size, :integer, :limit => 20
    change_column :filesystem_logs, :remote_size, :integer, :limit => 20
    change_column :mysql_logs, :table_id, :integer, :limit => 20
    change_column :mysql_logs, :database_id, :integer, :limit => 20
    change_column :mysql_logs, :local_size, :integer, :limit => 20
    change_column :mysql_logs, :remote_size, :integer, :limit => 20
    change_column :snapshots, :local_size, :integer, :limit => 20
    change_column :snapshots, :snapped_size, :integer, :limit => 20
    change_column :targets, :size, :integer, :limit => 20
  end

  def self.down
  end
end
