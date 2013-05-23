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

require 'restore/module'

module Restore
  module Modules

    class << self
      attr_accessor :enabled_modules
      @@enabled_modules = {}

      def load
        Dir.entries("#{RESTORE_ROOT}/modules").each do |d|
          if File.exists?("#{RESTORE_ROOT}/modules/#{d}/init.rb")
            require "#{RESTORE_ROOT}/modules/#{d}/init.rb"
          end
        end
      end
      
      def module_require_dependency(mod, path)
        require_dependency File.join(RESTORE_ROOT, 'modules', mod.to_s, path)
      end
      Object.send(:define_method, :module_require_dependency)  { |mod,path| Restore::Modules.module_require_dependency(mod,path)} unless Object.respond_to?(:module_require_dependency)
      
      
      def enabled_modules
        @@enabled_modules
      end
            
      def register(mod, options={})
        name = mod.to_s.split(/::/).last.downcase
        m = Restore::Module::Base.new(name, options)
        m.extend(mod)
        
        unless Restore::Config.disabled_modules.include?(name.to_sym)
          @@enabled_modules[name] = m
        end
      end

      def model_load_paths
        @@enabled_modules.collect {|name, mod|
          File.join(RESTORE_ROOT, 'modules', name, 'models')
        }
      end
      
      def controller_load_paths
        @@enabled_modules.collect {|name, mod|
          File.join(RESTORE_ROOT, 'modules', name, 'controllers')
        }
      end
      
      def require_dependencies
        @@enabled_modules.each do |name, mod|
          mod.require_dependencies
        end
      end

      def run_setup
        @@enabled_modules.each_pair do |name, mod|
          begin
            require "modules/#{name}/setup"
            klass = "Restore::Setup::#{name.camelize}".constantize
            klass.run
          rescue LoadError
          end
        end
      end
    end



  end
end
