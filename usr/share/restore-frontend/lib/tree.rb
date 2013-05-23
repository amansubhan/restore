module Tree
  module ControllerMixin
    def toggle_tree_object

      path_array = params[:tree_object_path].split(/\//)
      tree_id = path_array[0] rescue nil
      root = find_tree(tree_id)    
      if tree_id && root && (object = root.find_by_path_array(path_array[1..-1]))
        object.toggle_expanded
        render :update do |page|
          page.replace object.path, :partial => partial_path(object.partial_name), :locals => {:object => object}

          def expand_object(p, i)
            if i.container?
              i.children_values.reverse.each do |c|
                p.insert_html :after, i.path, :partial => partial_path(c.partial_name),
                :locals => {:object => c}

                expand_object(p, c) if c.container? && c.expanded
              end
            end
          end

          def collapse_object(p, i)
            if i.container? && i.children
              i.children.each do |id,c|
                p << "if ($('#{c.path}'))"
                p.replace c.path, ''
                collapse_object(p, c)
              end
            end
          end

          if object.expanded
            expand_object(page, object) 
          else
            collapse_object(page, object)
          end
        end # render
      else
        render :nothing => true
      end # object
    end

    def select_tree_object

      path_array = params[:tree_object_path].split(/\//)
      tree_id = path_array[0] rescue nil
      root = find_tree(tree_id)    
      if tree_id && root && (object = root.find_by_path_array(path_array[1..-1]))
        object.selected = params[:value] == '1' ? true : false

        if params[:deselect_parent] && !object.selected && object.parent
          object.parent.selected = false
        end

        if object.container? && object.children
          object.all_children.each do |c|
            c.selected = params[:value] == '1' ? true : false
          end
        end
        render :update do |page|
          if object.container? && object.children && object.expanded
            object.all_children.each do |c|
              page << "if($('#{c.path}'))"
              page.replace c.path, :partial => partial_path(c.partial_name), :locals =>{:object => c}
            end        
          end
          if params[:deselect_parent] && !object.selected && object.parent
            page << "if($('#{object.parent.path}'))"
            page.replace object.parent.path, :partial => partial_path(object.parent.partial_name), :locals =>{:object => object.parent}
          end
          page << "if($('#{object.path}'))"
          page.replace object.path, :partial => partial_path(object.partial_name), :locals =>{:object => object}
        end
      else
        render :nothing => true
      end
    end
  end
end