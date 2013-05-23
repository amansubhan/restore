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

require 'daemons'
require 'fastthread'
#require 'backgroundrb'
require 'backgroundrb/middleman'
require 'backgroundrb/scheduler'
require 'optparse'
require 'tmpdir'
require 'fileutils'

module BackgrounDRb
end

class BackgrounDRb::ServerScheduler
  def self.scheduler
    @@scheduler ||= BackgrounDRb::ScheduleMonitor.new
  end
end

class BackgrounDRb::ServerLogger
  def self.logfile=(file)
    @@logfile = file
  end
  def self.logger
    
    @@logger ||= ::Logger.new(@@logfile)
    log_file = @@logger.instance_variable_get('@logdev')

    # Daemons will close open file descriptors.
    if log_file.dev.closed?
      @@logger = ::Logger.new(@@logfile)
    end

    class << @@logger
      def format_message(severity, timestamp, progname, msg)
        "#{timestamp.strftime('%Y%m%d-%H:%M:%S')} (#{$$}) #{msg}\n"
      end
    end

    @@logger
  end

  def self.log_exception(component, e)
    BackgrounDRb::ServerLogger.logger.error(component) {
      "#{ e.message } - (#{ e.class })"
    }
    (e.backtrace or []).each do |line|
      BackgrounDRb::ServerLogger.logger.error(component) { 
        "#{line}" 
      }
    end
  end
end

class BackgrounDRb::Server


  def config

    Daemons::Controller::COMMANDS << 'console'
    program_args = Daemons::Controller.split_argv(ARGV)
    @cmd = program_args[0]
    backgroundrb_args = program_args[2]

    options = {}
        
    @app_option_parser = OptionParser.new do |opts|
      opts.banner = ""
      #opts.on("-c", "--config file_path", String, 
      #    "BackgrounDRb config file (path)") do |config|
      #  options[:config] = config
      #end

      #opts.on("-p", "--piddir file_path", String, 
      #    "BackgrounDRb PID directory (path)") do |piddir|
      #  options[:dir] = piddir
      #end

      #opts.on("-l", "--list", 
       #   "List configuration options") do 
      #  options[:list] = true
      #end

      #opts.on("-s", "--pool_size num", Integer, 
      #    "Thread pool size (default: 5)") do |pool_size| 
      #  options[:backend_pool_size] = pool_size
      #end

    end
    @app_option_parser.parse!(backgroundrb_args)

    @daemon_options = {
      :dir => Restore::Config.pid_dir,
      :dir_mode => :normal,
      :app_optparse => @app_option_parser
    }

    # Get common configuration options, including config file
    Restore::Config.load

    BackgrounDRb::ServerLogger.logfile = Restore::Config.log_dir + '/backgroundrb_server.log'

    @backgroundrb_options = options
  end

  def setup

    # Log server configuration
    case @cmd
    when 'start','run','restart'
      BackgrounDRb::ServerLogger.logger.info('server') do
        "Starting BackgrounDRb Server" 
      end
    end

    case @cmd
    when 'start','run'

      # Remove socket directory if it's already there - risky?
      socket_dir = File.join(Restore::Config.socket_dir, "backend.#{$$}")
      if File.directory?(socket_dir)
        FileUtils::rm_rf(socket_dir)
      end

      # We record this process pid as ppid, since Daemon's only will
      # record the a sub process pid, and we need a way to locate and
      # remove the socket directory when the server is stopped.
      #ppid_file = @daemon_options[:pid_file]
      #File.open(ppid_file, 'w') do |f|
      #  f.write(Process.pid)
      #end

      FileUtils::mkdir_p(socket_dir)

    #when 'restart'
    #  puts 'restart not supported, please stop, then start'
    #  exit 1

    end

    ENV['TMPDIR'] = socket_dir
  end


  # Remove socket directory if old ppid information is available
  def cleanup
    begin
      File.unlink(File.join(Restore::Config.socket_dir, 'restore_backend.sock'))
    rescue => e
      BackgrounDRb::ServerLogger.log_exception('server', e)
    end
  end

  def run

    # Process configuration and command line arguments into
    # configuration
    self.config

    # Setup server directories and load workers on server start
    self.setup

    # Run server block
    @server = Daemons.run_proc('restore_backend', @daemon_options) do 

      # Doesn't seem to work
      #at_exit { FileUtils::rm_rf(@backgroundrb_options[:socket_dir]) }

      middleman = BackgrounDRb::MiddleMan.instance.setup(
        :pool_size => Restore::Config.backend_pool_size,
        :scheduler => BackgrounDRb::ServerScheduler.scheduler,
        :worker_dir => @backgroundrb_options[:worker_dir],
        :logfile => Restore::Config.log_dir + '/backgroundrb.log'
      )

      # Disabled for now - will be configurable
      #$SAFE = 1   # disable eval() and friends
      socket = File.join(Restore::Config.socket_dir, 'restore_backend.sock')
      uri = "drbunix://" + socket
      
      require 'drb/timeridconv'
      DRb.install_id_conv DRb::TimerIdConv.new
      
      DRb.start_service(uri, middleman)
      DRb.thread.join
    end

    # Clean up temporary socket directory
    self.cleanup if @cmd == 'stop'

  end
end

module Daemons # :nodoc:

  # This class in BackgrounDRb overrides the behavior in Daemons in
  # order to kill the process. We expect to replace this with our own
  # daemon/server code at some point, as we don't really need the
  # application group facilities of Daemons.
  class Application # :nodoc:
=begin
    def stop
      if options[:force] and not running?
        self.zap
        return
      end

      # This is brute forcing the kill for platforms (Linux) where the
      # daemon process doesn't exit properly with TERM.
      begin
        pid = @pid.pid
        pgid =  Process.getpgid(@pid.pid)
        Process.kill('TERM', pid)
        Process.kill('-TERM', pgid)
        Process.kill('KILL', pid)
      rescue Errno::ESRCH => e
        puts "#{e} #{@pid.pid}"
        puts "deleting pid-file."
      end

      @pid.cleanup rescue nil
    end
  end

  # Override Daemons::Controller to include BackgrounDRb help output
  class Controller # :nodoc:

    def print_usage
      puts "Usage: #{@app_name} <command> <server_options> -- <backgroundrb options>"
      puts 
      puts "Commands: <command>"
      puts ""
      puts "  start         start backgroundrb server"
      puts "  stop          stop backroundrb server"
      puts "  restart       stop and restart backgrondrb server"
      puts "  run           start backgroundrb server and stay on top"
      puts "  zap           set backgroundrb server to stopped state"
      puts 
      puts "Server options: <server_options>:"
      puts @optparse.usage

      if @options[:app_optparse].is_a? OptionParser
        puts "\nBackgrounDRb options (after --)"
        puts @options[:app_optparse].to_s
      end
    end
=end
  end
end
