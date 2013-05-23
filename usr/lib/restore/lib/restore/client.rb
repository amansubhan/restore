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
  if dc_edition?
    class Client < ActiveRecord::Base
      # This class holds client information for the datacenter edition.
      
      require_dependency 'restore/installation'
      belongs_to :reseller, :class_name => 'Restore::Account::Reseller', :foreign_key => :reseller_id
      has_many :targets, :foreign_key => :client_id, :class_name => 'Restore::Target::Base', :dependent => :destroy
      has_many :users, :class_name => 'Restore::Account::User', :foreign_key => :client_id, :dependent => :destroy
      has_many :groups, :class_name => 'Restore::Account::Group', :foreign_key => :client_id, :dependent => :destroy
      has_many :accounts, :class_name => 'Restore::Account::Base', :foreign_key => :client_id

      validates_presence_of :name
      validates_uniqueness_of :name
      validates_numericality_of :quota

      def validate
        errors.add(:quota, _("must be greater than 0")) if quota <= 0
        errors.add(:quota, _("exceeds your quota")) if quota > reseller.quota
      end
      
      # the sum of all target sizes under this client
      # FRONTEND (perhaps backend as well, when sending emails)
      def size
        targets.inject(0) {|sum,t| sum + t.size}
      end

      # FRONTEND (perhaps backend as well, when sending emails)
      def space_percentage
        if quota == 0
          0.0
        else
          (size.to_f/quota)*100 rescue 0.0
        end
      end

      # FRONTEND (perhaps backend as well, when sending emails)
      def available_space
        quota - size
      end

      def installation
        @installation ||= Restore::Installation::DataCenter.new(self)
      end

    end
  end
end