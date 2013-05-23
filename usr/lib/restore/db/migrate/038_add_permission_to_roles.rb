class AddPermissionToRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :permission, :string
  end

  def self.down
    remove_column :roles, :permission
  end
end
