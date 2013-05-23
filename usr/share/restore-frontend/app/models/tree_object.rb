
module TreeContainer
  
  attr_reader :expanded
    
#  def initialize(id, options={})
#    super
#    @expanded = options[:expanded] ? true : false
#  end
  
  def container?
    true
  end
  
  def expanded?
    @expanded
  end
  
  
  def children
    load_children if expanded && @children.nil?
    @children
  end
  
  def children_values
    if c = children
      return c.values.sort {|a,b| a.name <=> b.name}
    else
      return []
    end
  end
  
  def load_children
    raise "abstract method"
  end
    
  def toggle_expanded
    @expanded = !expanded
  end
  
  def <<(child)
    @children ||= {}
    @children[child.id] = child
    child.parent = self
  end
    
  def [](id)
    @children[id]
  end

  def find_by_path(path)
    find_by_path_array(path.split(/\//))
  end
    
  def find_by_path_array(path_array)
    return self if path_array.nil? || path_array.empty?
    #path_array = path.split(/\//)
    if c = self[path_array[0]]
      if path_array.size == 1
        return c
      else
        return c.find_by_path_array(path_array[1..-1])
      end
    end
  end
  
  def all_children
    if children
      children.values + children.collect {|id,c|
        c.all_children if c.container?
      }.flatten.compact
    else
      []
    end
  end
  
  def all_children_ids
    if children
      #children.keys +
      children.collect {|id,c|
        [c.path] + c.all_children_ids
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


class TreeObject
  include GetText
  bindtextdomain("restore")
  
  attr_accessor :parent
  attr_reader :id
  attr_reader :partial_name
  attr_reader :name
  attr_reader :extra
  attr_accessor :selected
  attr_reader :options
  
  def initialize(id, options={})
    @options = options
    @id = id
    @parent = nil
    @children = nil
    @partial_name = options[:partial_name] if options[:partial_name]
    @name = options[:name] ? options[:name] : id
    @extra = options[:extra] ? options[:extra] : {}
    @selected = options[:selected] ? true : false
  end
  
  def container?
    false
  end
  
  def expanded?
    false
  end
  
  def path
    if parent
      parent.path+"/#{id}"
    else
      id
    end
  end
    
  def nesting
    parent.nil? ? 0 : parent.nesting + 1
  end
  
    
end