class AddIncludedToFilesystemFiles < ActiveRecord::Migration
  def self.up
    add_column :filesystem_files, :included, :boolean, :null => true
    Restore::Modules::Filesystem::File.find(:all).each do |f|
      f.included = !f.excluded
      f.save
    end
    remove_column :filesystem_files, :excluded
  end

  def self.down
    add_column :filesystem_files, :excluded, :boolean, :null => false
    Restore::Modules::Filesystem::File.find(:all).each do |f|
      f.excluded = !f.included?
      f.save
    end    
    remove_column :filesystem_files, :included    
  end
end
