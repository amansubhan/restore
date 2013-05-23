class AddEmailOptions < ActiveRecord::Migration
  def self.up
    add_column :accounts, :email_info, :boolean, :default => false
    add_column :accounts, :email_errors, :boolean, :default => false
  end

  def self.down
    remove_column :accounts, :email_info
    remove_column :accounts, :email_errors
  end
end
