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

class LoggerWorker < BackgrounDRb::Worker::Base

  def initialize(args=nil, jobkey=nil)
    @@logger ||= Logger.new(args['logfile'])
    class << @@logger
      def format_message(severity, timestamp, progname, msg)
        "#{timestamp.strftime('%Y%m%d-%H:%M:%S')} (#{$$}) #{msg}\n"
      end
    end
    @@logger.info("Starting WorkerLogger")
    super(args, jobkey)
  end

  def get_logger
    @@logger
  end

  def do_work(args)
  end
end
