class AddLocalSizeToSnapshot < ActiveRecord::Migration
  def self.up
    add_column :snapshots, :local_size, :integer,  :limit => 20, :default => 0
  end

  def self.down
    remove_column :snapshots, :local_size
  end
end
