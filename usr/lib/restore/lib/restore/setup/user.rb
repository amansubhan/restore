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

module Restore
  module Setup
    class User < Base
      class << self

        def run
          require File.join(RAILS_ROOT, 'config', 'environment')
          
          accounts = Restore::Account::DCAdmin.find(:all)
          if accounts.empty?
            puts "No administrator accounts have been created."
            name = ask('What username shall we use for the administrator account?', 'admin')
            
            loop do
              password = ask("What password shall we use?", nil, :echo => false)
              password_confirm = ask("Confirm password", nil, :echo => false)
              
              if password != password_confirm
                puts "Passwords do not match"
              else
                Restore::Account::DCAdmin.create(:name => name, :password => password)
                break
              end
            end  
          end
          
        end
      end
    end
  end
end