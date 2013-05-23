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

if dc_edition?
  module Restore
    module Account
      class Reseller < Base
        include GetText
        bindtextdomain("restore")
        
        require_dependency 'restore/client'

        has_many :clients, :class_name => 'Restore::Client', :foreign_key => :reseller_id, :dependent => :destroy    
        validates_numericality_of :quota

        def validate
          errors.add(:quota, _("must be greater than 0")) if quota <= 0
          errors.add(:quota, _("exceeds your quota")) if (Restore::Config.quota > 0) && (quota > Restore::Config.quota)
        end

        def default_controller
          '/reseller'
        end

        def quota_used
          clients.inject(0) {|s,t| s += t.quota} rescue 0
        end

        def quota_used_percentage
          (quota_used.to_f/quota)*100 rescue nil
        end
      end

    end
  end
end