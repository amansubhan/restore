class ChangeTargetClientId < ActiveRecord::Migration
  def self.up
    execute("ALTER TABLE `targets` CHANGE `client_id` `client_id` INT(11) NULL")
  end

  def self.down
  end
end
