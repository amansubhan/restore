class AddAccountIdToRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :account_id, :integer
  end

  def self.down
    remove_column :roles, :account_id
  end
end
