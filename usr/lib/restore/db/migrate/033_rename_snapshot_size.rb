class RenameSnapshotSize < ActiveRecord::Migration
  def self.up
    rename_column :filesystem_logs, :snapshot_size, :remote_size
  end

  def self.down
    rename_column :filesystem_logs, :remote_size, :snapshot_size
  end
end
