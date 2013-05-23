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

module Restore
  class Config
    class << self
      
      @@config = nil
      def load
        unless defined?(CONFIG_PATH)
          # XXX add a way to pull from the environment
          require File.join(RESTORE_ROOT, 'config', 'config_path')
        end

        if @@config.nil?
          defaults = {
            :env => ENV['RAILS_ENV'] || 'development',
            :log_dir => File.join(RESTORE_ROOT, 'log'),
            :pid_dir => File.join(RESTORE_ROOT, 'tmp', 'pids'),
            :socket_dir => '/tmp', # need to keep as short of a path as possible
            :backend_pool_size => 5,
            :backups => File.join(RESTORE_ROOT, 'backups'),
            :quota => 0,
            :disabled_modules => [:local]
          }

          require 'ostruct'
          require 'yaml'
          require 'erb'
          options = {}
          begin
            raw = YAML.load(ERB.new(IO.read(File.join(CONFIG_PATH, 'restore.yml'))).result)

            # make top level string keys into symbols (compatibility)
            conf_as_sym = {}
            raw.each_key do |key|
              conf_as_sym[key.to_sym] = raw[key]
            end
            options = defaults.merge(conf_as_sym)
          rescue
            options = defaults
          end
          @@config = OpenStruct.new(options)
          @@config.disabled_modules = [] if @@config.disabled_modules.nil?
          
          ENV['RAILS_ENV'] ||= @@config.env
          ENV["RESTORE_ENV"] ||= @@config.env
          #::RESTORE_ENV = @@config.env
        end
      end
      
      def quota
        case @@config.quota
        when /(\d+)TB?$/i
          $1.to_i*1.terabyte
        when /(\d+)GB?$/i
          $1.to_i*1.gigabyte
        when /(\d+)MB?$/i
          $1.to_i*1.megabyte
        when /(\d+)KB?$/i
          $1.to_i*1.kilobyte
        else
          @@config.quota.to_i
        end
      end
            
      def method_missing(cmd, *arg)
        @@config.send(cmd, *arg) if @@config
      end
      
    end
  end

end
