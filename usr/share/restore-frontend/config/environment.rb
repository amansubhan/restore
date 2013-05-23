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

# Be sure to restart your web server when you modify this file.

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require File.join(RESTORE_ROOT, 'config', 'environment')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  config.database_configuration_file = File.join(CONFIG_PATH, 'database.yml')
  config.log_path = File.join(Restore::Config.log_dir, 'restore.log')

  config.controller_paths += Restore::Modules.controller_load_paths
  config.load_paths += Restore::Modules.model_load_paths

end

::Dependencies.load_paths += Restore::Modules.controller_load_paths
::Dependencies.load_paths << File.join(RESTORE_ROOT, 'lib')

# load up Restore library
require_dependency 'restore/target'
require_dependency 'restore/snapshot'
Restore::Modules.require_dependencies

require 'frontend_override'
require 'juggernaut'
require 'juggernaut_helper'
ActionView::Helpers::AssetTagHelper::register_javascript_include_default('swfobject')
ActionView::Helpers::AssetTagHelper::register_javascript_include_default('juggernaut')
ActionView::Base.send(:include, Juggernaut::JuggernautHelper)
ActionController::Base.class_eval do
  include Juggernaut::RenderExtension
end


$KCODE = 'u'
require 'jcode'
require 'gettext/rails'