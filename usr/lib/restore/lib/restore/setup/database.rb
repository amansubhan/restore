# Copyright (c) 2006, 2007 Ruffdogs Software, Inc.
# Authors: Adam Lebsack <adam@holonyx.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.


require 'restore/setup/base'
require 'mysql'
require 'fileutils'
module Restore
  module Setup
    class Database < Base
      class << self

        def check_database(dbconfig)
          devdb = dbconfig['development']
          dbh = ::Mysql.real_connect(devdb['host'], devdb['username'], devdb['password'], devdb['database'])
          true
        end

        def create_database(dbh, dbconfig)
          dbh.query("create database #{dbconfig['development']['database']}")
        rescue => e
          puts e.to_s
        end

        def create_database_user(dbconfig)
          devdb = dbconfig['development']


          dbh = ::Mysql.real_connect(devdb['host'], admin_username, admin_password, 'mysql')

          dbh.query("INSERT INTO user (Host,User,Password) VALUES('localhost','#{devdb['username']}','#{devdb['password']}');")
          dbh.query('FLUSH PRIVILEGES;')
          dbh.query("GRANT ALL PRIVILEGES ON #{devdb['dbname']} TO '#{devdb['username']}'@'localhost';")
        end

        def check_database_admin
          @admin_username ||= 'root'
          @admin_username = ask("What is the admin username of the database server?", @admin_username)
          @admin_password = ask("What is the admin password of the database server?", '', :echo => false)
          ::Mysql.real_connect('localhost', @admin_username, @admin_password, 'mysql')
        rescue => e
          puts e.to_s
          check_database_admin
        end

        def check_restore_database(dbconfig)
          dbconfig ||= {}
          dbconfig['development'] ||= {}
          dbconfig['development']['adapter'] = 'mysql'
          dbconfig['development']['host'] = 'localhost'
          devdb = dbconfig['development']

          #devdb['host'] = ask("What is the host of the database server?", devdb['host'])

          devdb['username'] = ask("What is the Restore database username?", devdb['username'])
          devdb['password'] = ask("What is the Restore database password?", '', :echo => false)
          devdb['database'] = ask("What is the name of Restore database?", devdb['database'])
          dbconfig['production'] = devdb.clone

          devdb = dbconfig['development']
          dbh = ::Mysql.real_connect(devdb['host'], devdb['username'], devdb['password'], devdb['database'])
        end

        def run
          # Begin execution
          @config = Rails::Configuration.new
          @config.database_configuration_file = File.join(CONFIG_PATH, 'database.yml')
          FileUtils.touch(@config.database_configuration_file) unless File.exist?(@config.database_configuration_file)          
          dbconfig = @config.database_configuration
          dbconfig ||= {}
          dbconfig['development'] ||= {}
          
          config_db = false
          begin
            check_database(dbconfig)
            config_db = ask_bool("Database configuration looks good.  Do you wish to reconfigure it?", false)
          rescue
            config_db = true
          end

          if config_db
            admin_dbh = check_database_admin

            loop do
              begin
                check_restore_database(dbconfig)
                File.open(@config.database_configuration_file, 'w') do |out|
                  YAML.dump(dbconfig, out )
                end
                break
              rescue => e
                # attempt to solve the problem.
                case
                when e.to_s =~ /^Access denied/
                  if ask_bool("Access denied.  Do you wish to create the user?", true)
                    admin_dbh.query("INSERT INTO user (Host,User,Password) VALUES('localhost','#{dbconfig['development']['username']}','#{dbconfig['development']['password']}');")
                    admin_dbh.query('FLUSH PRIVILEGES;')
                  end
                  # otherwise ask for settings again
                when e.to_s =~ /^Unknown database/
                  if ask_bool("Database does not exist.  Do you wish to create it?", true)
                    create_database(admin_dbh, dbconfig)
                    break if check_database(dbconfig)

                  end
                  # otherwise ask for settings again
                else
                  puts "Database configuration invalid: "+e.to_s
                  #configure_database(dbconfig)
                end

              end
            end
          end

          Rails::Initializer.run(:process, @config)
          
          require File.join(RAILS_ROOT, 'config', 'environment')
          #require 'active_record'
          puts
          puts "Updating database..."
          ActiveRecord::Migrator.migrate(File.join(RAILS_ROOT, 'db', 'migrate'), nil)
        end
      end
    end
  end
end