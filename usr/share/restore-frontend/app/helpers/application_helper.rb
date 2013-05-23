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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def focus_on_load(id)
    javascript_tag("Event.observe(window,'load',function(){$('#{id}').focus();})")
  end

  def super_partial_path(partial)
    @controller.super_partial_path(partial)
  end
  def partial_path(partial)
    @controller.partial_path(partial)
  end

  def human_size(size, precision=2)
    size = Kernel.Float(size)
    case 
      when size == 1        : "1 Byte"
      when size < 1.kilobyte: "%d Bytes" % size
      when size < 1.megabyte: "%.#{precision}f KB"  % (size / 1.0.kilobyte)
      when size < 1.gigabyte: "%.#{precision}f MB"  % (size / 1.0.megabyte)
      when size < 1.terabyte: "%.#{precision}f GB"  % (size / 1.0.gigabyte)
      else                    "%.#{precision}f TB"  % (size / 1.0.terabyte)
    end #.sub('.0', '')
  rescue
    ''
  end

  def inside_layout(layout, &block)
    @template.instance_variable_set("@content_for_layout", capture(&block))
    layout = layout.include?("/") ? layout : "layouts/#{layout}" if layout
    buffer = eval("_erbout", block.binding)
    buffer.concat(@template.render_file(layout, true))
  end

  def listtable_header(cols, list_id=nil)
    buffer = '<thead><tr>'
    if list_id
      column = @controller_session[:list][list_id][:sort] rescue ''
      reverse = @controller_session[:list][list_id][:reverse] rescue false
      cols.each do |c|
        colname = ''
        if c.class == Array
          colname = c[0]
          attrs = c[1]
        else
          colname = c
          attrs = ''
        end

        if colname.empty? || c == '&nbsp;'
          buffer += "<th #{attrs}>&nbsp;</th>"
        else
          css_class = ""
          css_class = reverse ? "sortedASC" : "sortedDESC" if column == colname
          buffer += "<th class=\"#{css_class}\" #{attrs}>"+link_to_remote(colname, :url => {:action => :update_list, :sort => colname, :list_id => list_id})+"</th>"
        end
      end
    else
      # no sorting
      cols.each do |c|
        colname = ''
        if c.class == Array
          colname = c[0]
          attrs = c[1]
        else
          colname = c
          attrs = ''
        end
        
        if colname.empty? || colname == '&nbsp;'
          buffer += "<th #{attrs}>&nbsp;</th>"
        else
          buffer += "<th #{attrs}>#{colname}</th>"
        end
      end
    end  
    buffer += '</tr></thead>'
    buffer
  end

  def file_image(file)
    case file.file_type
    when 'S'
      'file.png'
    when 'L'
      'link.png'
    when 'F'
      'file.png'
    when 'B'
      'file.png'
    when 'D'
      'folder.png'
    when 'C'
      'file.png'
    when 'I'
      'file.png'
    end
  end
  
  def human_file_type(type)
    case type
    when 'S'
      'Socket'
    when 'L'
      'Symbolic Link'
    when 'F'
      'File'
    when 'B'
      'Block Device'
    when 'D'
      'Directory'
    when 'C'
      'Character Device'
    when 'I'
      'FIFO'
    end
  end
  
  def tooltip(path)
    id = path.gsub(/\//, '_')
    path2 = path.split('/')
    
    if path2[1] == 'modules'
      begin
        help_content = File.read(File.join(RESTORE_ROOT, 'modules', path2[2], 'views', 'tooltips', path2[3..-1].join('/')+'.html'))
      rescue
        help_content = nil
      end
    else
      help_content = render(:partial => File.join('/tooltips', path))
    end
    
    tooltip2(help_content, id)
  end
  
  def tooltip2(text, id = nil)
    buffer = ''
    id = Time.now.usec if id.nil?
    
    if text
      buffer += "<div class=\"tooltip_contents\" id=\"tooltip_#{id}\">"
      buffer += text
      buffer += "<br/><center>"
      buffer += button_to_function 'close', "$('tooltip_#{id}').style.display=\"none\"", :class => 'cancel'
      buffer += "</center></div>"
      buffer += link_to_function image_tag('help.png'), "$('tooltip_#{id}').style.display=\"block\""
    end
    buffer
    
  end

end
