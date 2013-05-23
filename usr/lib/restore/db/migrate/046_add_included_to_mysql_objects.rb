class AddIncludedToMysqlObjects < ActiveRecord::Migration
  def self.up
    add_column :mysql_databases, :included, :boolean, :null => true
    Restore::Modules::Mysql::Database.find(:all).each do |db|
      db.included = !db.excluded
      db.save
    end
    remove_column :mysql_databases, :excluded
    
    add_column :mysql_tables, :included, :boolean, :null => true
    Restore::Modules::Mysql::Table.find(:all).each do |t|
      t.included = !t.excluded
      t.save
    end
    remove_column :mysql_tables, :excluded
  end

  def self.down
    add_column :mysql_tables, :excluded, :boolean, :null => false
    Restore::Modules::Mysql::Table.find(:all).each do |t|
      t.excluded = !t.included?
      t.save
    end
    remove_column :mysql_tables, :included    

    add_column :mysql_databases, :excluded, :boolean, :null => false
    Restore::Modules::Mysql::Database.find(:all).each do |db|
      db.excluded = !db.included?
      db.save
    end
    remove_column :mysql_databases, :included    
  end
end
