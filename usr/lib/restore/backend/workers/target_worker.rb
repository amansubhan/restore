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

require 'workers/base_worker'
class TargetWorker < ::BaseWorker
  def do_work(args)
    super

    class_name = args[:target_class].constantize.worker_class
    type = class_name.split(/::/)[-1].underscore
    results[:error] = nil
    results[:completed] = false
    
    begin
      module_require_dependency type, 'worker'
      klass = class_name.constantize
      klass.logger = logger
      
      res = klass.send(args[:method], *args[:method_args])
      res.each do |k,v|
        results[k] = v
      end
      
    rescue => e
      logger.info e.to_s+e.backtrace.join("\n")
      results[:error] = e.to_s
    end
    results[:completed] = true
    logger.info args[:oncomplete].inspect
    
    ::Juggernaut.send_to(args[:session_id], args[:oncomplete]) if args[:oncomplete]
  end
end
