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

module ResellerClientTree
  require_dependency 'reseller_client_tree/root'
  require_dependency 'reseller_client_tree/client'
  require_dependency 'reseller_client_tree/user'
  require_dependency 'reseller_client_tree/group'
  require_dependency 'reseller_client_tree/target'
end