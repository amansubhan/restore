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

module Restore::Module
  
  class Base
    include GetText
    bindtextdomain("restore")
          
    attr_accessor :name
    attr_reader :abstract
    
    def initialize(name, options={})

      defaults = {
        :abstract => false
      }
      options = defaults.merge(options)
      
      @abstract = options[:abstract]
      @name = name
    end
      
    def target_class
      module_require_dependency name, 'target'
      "Restore::Target::#{name.camelcase}".constantize
    end

    def snapshot_class
      target_class.snapshot_class
    end

    def require_dependencies
      target_class
      snapshot_class
    end
      
    def description
      ''
    end
      
  end
end
