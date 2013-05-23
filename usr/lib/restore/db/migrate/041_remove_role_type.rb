class RemoveRoleType < ActiveRecord::Migration
  def self.up
    remove_column :roles, :type
  end

  def self.down
    add_column :roles, :type, :string
  end
end
