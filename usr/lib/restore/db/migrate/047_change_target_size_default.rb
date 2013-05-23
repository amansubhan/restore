class ChangeTargetSizeDefault < ActiveRecord::Migration
  def self.up
    change_column :targets, :size, :integer, :limit => 20, :null => false, :default => 0
  end

  def self.down
  end
end
