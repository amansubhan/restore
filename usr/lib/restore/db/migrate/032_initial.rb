class Initial < ActiveRecord::Migration
  def self.up
    execute "ALTER DATABASE #{connection.current_database} CHARACTER SET 'latin1' COLLATE 'latin1_general_cs'"
    
    create_table "accounts", :force => true do |t|
      t.column "name",            :string,                :default => "",    :null => false
      t.column "first_name",      :string
      t.column "last_name",       :string
      t.column "email",           :string
      t.column "hashed_password", :string
      t.column "type",            :string
      t.column "client_id",       :integer
      t.column "admin",           :boolean,               :default => false
      t.column "quota",           :integer, :limit => 20
    end

    create_table "clients", :force => true do |t|
      t.column "name",        :string,                :default => "", :null => false
      t.column "reseller_id", :integer
      t.column "quota",       :integer, :limit => 20
    end

    create_table "filesystem_files", :force => true do |t|
      t.column "target_id", :integer
      t.column "parent_id", :integer
      t.column "filename",  :text
      t.column "path",      :text
      t.column "excluded",  :boolean, :default => false, :null => false
    end

    add_index "filesystem_files", ["parent_id"], :name => "parent_id"
    execute("CREATE INDEX `parent_filenames` ON filesystem_files (`target_id`, `parent_id`, `filename`(512))")

    create_table "filesystem_logs", :force => true do |t|
      t.column "snapshot_id",   :integer
      t.column "file_id",       :integer,  :limit => 20, :default => 0,     :null => false
      t.column "event",         :string,   :limit => 1
      t.column "file_type",     :string,   :limit => 1
      t.column "mtime",         :datetime
      t.column "btime",         :datetime
      t.column "error",         :text
      t.column "params",        :text
      t.column "target_id",     :integer
      t.column "local_size",    :integer,  :limit => 20
      t.column "extra",         :text
      t.column "snapshot_size", :integer
      t.column "pruned",        :boolean,                :default => false
    end

    add_index "filesystem_logs", ["snapshot_id", "file_id"], :name => "snapshot_id", :unique => true
    add_index "filesystem_logs", ["btime"], :name => "btime"
    add_index "filesystem_logs", ["pruned"], :name => "pruned"
    add_index "filesystem_logs", ["event"], :name => "event"
    add_index "filesystem_logs", ["file_id"], :name => "file_id"

    create_table "groups_users", :id => false, :force => true do |t|
      t.column "user_id",  :integer
      t.column "group_id", :integer
    end

    create_table "mysql_databases", :force => true do |t|
      t.column "target_id", :integer
      t.column "name",      :text
      t.column "excluded",  :boolean, :default => false, :null => false
    end

    create_table "mysql_logs", :force => true do |t|
      t.column "target_id",    :integer
      t.column "snapshot_id",  :integer
      t.column "type",         :string
      t.column "database_id",  :integer,  :limit => 20
      t.column "table_id",     :integer,  :limit => 20
      t.column "event",        :string,   :limit => 1
      t.column "table_engine", :string
      t.column "table_type",   :string
      t.column "mtime",        :datetime
      t.column "btime",        :datetime
      t.column "error",        :text
      t.column "params",       :text
      t.column "local_size",   :integer,  :limit => 20
      t.column "extra",        :text
    end

    add_index "mysql_logs", ["target_id", "database_id", "table_id", "snapshot_id"], :name => "target_id", :unique => true
    add_index "mysql_logs", ["table_id", "btime"], :name => "table_id"

    create_table "mysql_tables", :force => true do |t|
      t.column "target_id",   :integer
      t.column "database_id", :integer
      t.column "name",        :text
      t.column "excluded",    :boolean, :default => false, :null => false
    end

    create_table "revision_schedules", :force => true do |t|
      t.column "target_id",  :integer
      t.column "interval",   :integer
      t.column "since",      :integer
      t.column "since_unit", :string
    end

    create_table "roles", :force => true do |t|
      t.column "type",        :string
      t.column "entity_id",   :integer
      t.column "entity_type", :string
      t.column "target_id",   :integer
    end

    create_table "sessions", :force => true do |t|
      t.column "session_id", :string
      t.column "data",       :longtext
      t.column "updated_at", :datetime
    end

    add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
    add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

    create_table "snapshots", :force => true do |t|
      t.column "target_id",    :integer,                :default => 0, :null => false
      t.column "prep_start",   :datetime
      t.column "prep_end",     :datetime
      t.column "start_time",   :datetime
      t.column "end_time",     :datetime
      t.column "error",        :text
      t.column "pid",          :integer,                :default => 0, :null => false
      t.column "type",         :string
      t.column "created_at",   :datetime
      t.column "snapped_size", :integer,  :limit => 20, :default => 0
    end

    create_table "target_schedules", :force => true do |t|
      t.column "target_id", :integer,                  :null => false
      t.column "min",       :string,  :default => "*", :null => false
      t.column "hour",      :string,  :default => "*", :null => false
      t.column "day",       :string,  :default => "*", :null => false
      t.column "month",     :string,  :default => "*", :null => false
      t.column "weekday",   :string,  :default => "*", :null => false
      t.column "name",      :string,  :default => "",  :null => false
    end

    create_table "targets", :force => true do |t|
      t.column "name",      :string
      t.column "type",      :string
      t.column "path",      :string
      t.column "hostname",  :string
      t.column "username",  :string
      t.column "password",  :string
      t.column "sharename", :string
      t.column "owner_id",  :integer
      t.column "extra",     :text
      t.column "client_id", :integer,               :null => false
      t.column "size",      :integer, :limit => 20
    end
    
  end

  def self.down
    raise IrreversibleMigration
  end
  
  private
  def self.connection
    ActiveRecord::Base.connection
  end
end
