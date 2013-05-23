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
  require 'gettext'
  class Role < ActiveRecord::Base
    include GetText
    bindtextdomain("restore")
    
    belongs_to :account, :class_name => 'Restore::Account::Base', :foreign_key => :account_id
    belongs_to :target, :class_name => 'Restore::Target::Base', :foreign_key => 'target_id'

    validates_presence_of :account_id
    validates_uniqueness_of :account_id, :scope => :target_id
    validates_associated :account
    
    validates_presence_of :target_id    
    validates_associated :target

    def permission_string
      case permission
      when 'r'
        _('Read')
      when 'rw'
        _('Read/Write')
      when 'a'
        _('Admin')
      end
    end
    
  end
end