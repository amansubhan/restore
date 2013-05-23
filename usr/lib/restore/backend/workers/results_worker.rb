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

class ResultsWorker < BackgrounDRb::Worker::Base
  include MonitorMixin

  def initialize(args=nil, jobkey=nil)
    @worker_results = {}
    super(args, jobkey)
  end

  def do_work(args)
    logger.info("In ResultsWorker")
  end

  def set_result(job_key, result)
    synchronize do
      @worker_results[job_key] ||= Hash.new
      @worker_results[job_key].merge!(result)
    end
  end

  def get_result(job_key, result_key)
    @worker_results[job_key] ||= Hash.new
    if @worker_results[job_key][result_key]
      return @worker_results[job_key][result_key]
    end
  end

  def get_worker_results(job_key)
    @worker_results[job_key] ||= Hash.new
    worker_result = @worker_results[job_key]
    return worker_result
  end

end