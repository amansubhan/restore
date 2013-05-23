# = About lib/railsdav.rb
$:.unshift File.expand_path(File.dirname(__FILE__))

module Railsdav
  VERSION = '0.0.2'
end

require 'railsdav/errors'
require 'railsdav/callbacks'
require 'railsdav/resource'
require 'railsdav/propxml'
require 'railsdav/act_as_railsdav'

require 'railsdav/rails_monkey_patch'

require 'webdav/act_as_filewebdav'
require 'webdav/file_resource'

