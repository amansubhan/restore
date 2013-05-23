class ForceBigInt2 < ActiveRecord::Migration
  def self.up
    execute("ALTER TABLE filesystem_files CHANGE id id bigint NOT NULL auto_increment")
    change_column :filesystem_files, :parent_id, :integer, :limit => 20
    execute("ALTER TABLE filesystem_logs CHANGE id id bigint NOT NULL auto_increment")
  end

  def self.down
  end
end
