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
# Patch Activerecord for rails ticket #7293


# http://dev.rubyonrails.org/ticket/7293
class ActiveRecord::Base
  def unserialize_attribute(attr_name)
    unserialized_object = object_from_yaml(@attributes[attr_name])
    if unserialized_object.is_a?(self.class.serialized_attributes[attr_name]) || unserialized_object.nil?
      @attributes[attr_name] = unserialized_object
    else
      raise SerializationTypeMismatch,
        "#{attr_name} was supposed to be a #{self.class.serialized_attributes[attr_name]}, but was a #{unserialized_object.class.to_s}"
    end
  end
end


# add support for the column types we need.
class ActiveRecord::ConnectionAdapters::MysqlAdapter
  def type_to_sql(type, limit = nil, precision = nil, scale = nil) #:nodoc:
  	return 'bigint' if type.to_s == 'integer' and limit.to_i > 11 
  	return 'longtext' if type.to_s == 'longtext' 
  	super
  end
  
  alias_method :orig_native_database_types, :native_database_types
  def native_database_types #:nodoc:
    hash = orig_native_database_types
    hash[:longtext]  = { :name => "longtext" }
    hash
  end
end

class ActiveRecord::ConnectionAdapters::Column
  alias_method :orig_simplified_type, :simplified_type
  def simplified_type(field_type)

    case field_type
    when /longtext/i
      :longtext
    else
      orig_simplified_type(field_type)
    end
  end
end
