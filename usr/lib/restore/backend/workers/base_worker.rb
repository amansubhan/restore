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

class BaseWorker < BackgrounDRb::Worker::Base
  require 'backgroundrb/target_log_dev'
  class JuggernautLogDev
    def initialize(target_id)
      @target_id = target_id
    end
    
    def write(str)
      # this is a little ridiculous
      #escaped = Juggernaut.html_escape(str).gsub("\n", '\\\\\n').gsub("'", "\\\\\\\\'")
      escaped = Juggernaut.html_escape(str).gsub("\n", '<br/>').gsub("'", "\\\\\\\\'")
      
      Juggernaut.send_data("append_log('#{escaped}');", ["target_#{@target_id}".to_sym])
    end
    
    def close  
    end
  end
  
  def do_work(args)
    require RESTORE_ROOT + '/config/environment.rb'
    Dir.chdir(RESTORE_ROOT)
  end

end
