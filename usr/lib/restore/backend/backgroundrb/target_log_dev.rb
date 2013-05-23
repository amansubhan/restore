# Copyright (c) 2006, 2007 Ruffdogs Software, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

module BackgrounDRb

  class TargetLogDev
    def initialize(target_id, name)
      @logfile = File.open(File.join(Restore::Config.log_dir, "target_#{target_id}.log"), File::CREAT|File::RDWR|File::APPEND, 0640)
      @target_id = target_id
    end
    
    def write(str)
      # this is a little ridiculous
      @logfile.write(str)
      #escaped = Juggernaut.html_escape(str).gsub("\n", '\\\\\n').gsub("'", "\\\\\\\\'")
       escaped = Juggernaut.html_escape(str).gsub("\n", '<br/>').gsub("'", "\\\\\\\\'")
      
      Juggernaut.send_data("append_log('#{escaped}');", ["target_#{@target_id}".to_sym])
    end
    
    def close  
      @logfile.close
    end
  end

end
