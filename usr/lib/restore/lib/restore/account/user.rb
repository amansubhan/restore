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
  module Account

    require 'digest/md5'
    require 'restore/notifier'

    class User < ClientAccount
      has_and_belongs_to_many :groups, :class_name => 'Restore::Account::Group'
      has_many :targets, :foreign_key => :owner_id, :class_name => 'Restore::Target::Base'

      def default_controller
        self.use_home_page ? '/home' : '/targets'
      end

      def is_admin?
        return true if admin?
        groups.each do |g|
          return true if g.admin?
        end
        return false
      end

      def send_error_email(subject, error)
        if email && email_errors
          Restore::Notifier.deliver_error_notification(email, name, subject, error)
        end
      end

      def send_info_email(subject, info)
        if email && email_info
          Restore::Notifier.deliver_notification(email, name, subject, info)
        end
      end




      def can_read_target?(target)
        return false if (dc_edition? && !self.client.targets.include?(target))
        return true if target.owner == self
        return true if self.is_admin?
        target.roles.each do |r|
          if r.account == self
            return true if ['r', 'rw', 'a'].include?(r.permission)
          elsif r.account.class == Restore::Account::Group && groups.include?(r.account)
            return true if ['r', 'rw', 'a'].include?(r.permission)          
          end
        end
        return false
      end

      def can_write_target?(target)
        return false if (dc_edition? && !self.client.targets.include?(target))
        return true if target.owner == self
        return true if self.is_admin?
        target.roles.each do |r|
          if r.account == self
            return true if ['rw', 'a'].include?(r.permission)
          elsif r.account.class == Restore::Account::Group && groups.include?(r.account)
            return true if ['rw', 'a'].include?(r.permission)          
          end
        end
        return false
      end

      def can_admin_target?(target)
        return false if (dc_edition? && !self.client.targets.include?(target))
        return true if target.owner == self
        return true if self.is_admin?
        target.roles.each do |r|
          if r.account == self
            return true if ['a'].include?(r.permission)
          elsif r.account.class == Restore::Account::Group && groups.include?(r.account)
            return true if ['a'].include?(r.permission)          
          end
        end
        return false
      end



    end

  end
end