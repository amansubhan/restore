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

class TreeItem
  include GetText
  bindtextdomain("restore")
  
  attr_accessor :parent
  attr_reader :id
  attr_reader :expanded
  attr_reader :partial_name
  attr_reader :name
  attr_reader :extra
  attr_accessor :selected
    
  def initialize(id, options={})
    @id = id
    @parent = nil
    @children = nil
    @partial_name = options[:partial_name] if options[:partial_name]
    @name = options[:name] ? options[:name] : id
    @expanded = options[:expanded] ? true : false
    @extra = options[:extra] ? options[:extra] : {}
    @selected = options[:selected] ? true : false
  end
  
  def children
    load_children if expanded && @children.nil?
    @children
  end
  
  def children_values
    children.values.sort {|a,b| a.name <=> b.name}
  end
  
  
  def load_children
    @children = {}
  end
  
  def full_id
    if parent
      parent.full_id+"[#{id}]"
    else
      id
    end
  end
  
  def toggle_expanded
    @expanded = !expanded
  end
  
  def <<(child)
    @children ||= {}
    @children[child.id] = child
    child.parent = self
  end
  
  def nesting
    parent.nil? ? 0 : parent.nesting + 1
  end
  
  def [](id)
    @children[id]
  end
  
  def find_by_id(full_id)
    return self if full_id == self.id
    
    full_id = full_id.gsub /^.*?(\[)/, '\1' if parent.nil?
    if matches = Regexp.new(/^\[(.*?)\]/).match(full_id)
      if matches[1]
        if c = self[matches[1]]
          if matches.post_match.empty?
            return c
          else
            return c.find_by_id(matches.post_match)
          end
        end
      end
    end
    nil
  end
  
  def all_children
    if children
      children.values + children.collect {|id,c|
        c.all_children
      }.flatten.compact
    else
      []
    end
  end
  
  def all_children_ids
    if children
      #children.keys +
      children.collect {|id,c|
        [c.full_id] + c.all_children_ids
      }.flatten.compact
    else
      []
    end
  end
  
  def all_selected
    selected = []
    selected << self if self.selected
    if children
      selected += children.collect {|id,c|
        c.all_selected
      }.flatten.compact
    end
    selected
  end
  
end