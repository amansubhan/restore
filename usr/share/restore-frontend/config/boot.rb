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

# Don't change this file. Configuration is done in config/environment.rb and config/environments/*.rb
begin
  require 'rubygems'
rescue LoadError
end

unless defined?(RESTORE_ROOT)
  require File.join(File.dirname(__FILE__), 'restore_root.rb')
end
require File.join(RESTORE_ROOT, 'config', 'boot')

unless defined?(RAILS_ROOT)
  root_path = File.join(File.dirname(__FILE__), '..')

  require 'pathname'
  root_path = Pathname.new(root_path).cleanpath(true).to_s
  RAILS_ROOT = root_path
end

unless defined?(Rails::Initializer)
  if File.directory?("#{RESTORE_ROOT}/vendor/rails")
    ::RAILS_FRAMEWORK_ROOT = "#{RESTORE_ROOT}/vendor/rails"
    require "#{RESTORE_ROOT}/vendor/rails/railties/lib/initializer"
  else
    require 'rubygems'
    environment_without_comments = IO.readlines(File.dirname(__FILE__) + '/environment.rb').reject { |l| l =~ /^#/ }.join
    environment_without_comments =~ /[^#]RAILS_GEM_VERSION = '([\d.]+)'/
    rails_gem_version = $1

    if version = defined?(RAILS_GEM_VERSION) ? RAILS_GEM_VERSION : rails_gem_version
      # Asking for 1.1.6 will give you 1.1.6.5206, if available -- makes it easier to use beta gems
      rails_gem = Gem.cache.search('rails', "~>#{version}.0").sort_by { |g| g.version.version }.last
      if rails_gem
        gem "rails", "=#{rails_gem.version.version}"
        require rails_gem.full_gem_path + '/lib/initializer'
      else
        STDERR.puts %(Cannot find gem for Rails ~>#{version}.0:
    Install the missing gem with 'gem install -v=#{version} rails', or
    change environment.rb to define RAILS_GEM_VERSION with your desired version.
  )
        exit 1
      end
    else
      gem "rails"
      require 'initializer'
    end
  end
  Rails::Initializer.run(:set_load_path)
end
