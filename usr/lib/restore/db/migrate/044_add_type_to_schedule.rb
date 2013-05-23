class AddTypeToSchedule < ActiveRecord::Migration
  def self.up
    add_column :target_schedules, :type, :string, :default => 'Advanced'
  end

  def self.down
    remove_column :target_schedules, :type   
  end
end
