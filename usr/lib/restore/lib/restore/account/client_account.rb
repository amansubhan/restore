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

    class ClientAccount < Base
      abstract_class = true

      if dc_edition?
        belongs_to :client, :class_name => 'Restore::Client', :foreign_key => :client_id
      end


      def installation
        if dc_edition?
          client.installation
        else
          @installation ||= Restore::Installation::Enterprise.new
        end
      end

    end
  end
end