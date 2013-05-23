class AddHomepagePreference < ActiveRecord::Migration
  def self.up
    add_column :accounts, :use_home_page, :boolean, :default => true    
  end

  def self.down
    remove_column :accounts, :use_home_page   
  end
end
