require 'active_support'
require 'fileutils'

require_library_or_gem 'fcgi'

#%w(cache pids sessions sockets).each { |dir_to_make| FileUtils.mkdir_p(File.join(RESTORE_ROOT, 'tmp', dir_to_make)) }
%w(cache pids sessions sockets).each { |dir_to_make| FileUtils.mkdir_p(File.join(RAILS_ROOT, 'tmp', dir_to_make)) }

require 'rbconfig'

lighttpd = File.join(RAILS_ROOT, 'bin', 'lighttpd')
if !File.exist?(File.join(RAILS_ROOT, 'bin', 'lighttpd'))
  lighttpd = 'lighttpd'
  unless RUBY_PLATFORM !~ /mswin/ && !silence_stderr { `lighttpd -version` }.blank?
    puts "PROBLEM: Lighttpd is not available on your system (or not in your path)"
    exit 1
  end
end

unless defined?(FCGI)
  puts "PROBLEM: Lighttpd requires that the FCGI Ruby bindings are installed on the system"
  exit 1
end


# added in order tot ail the proper log file
require File.join(RESTORE_ROOT, 'lib', 'restore', 'config')
Restore::Config.load
configuration = Rails::Initializer.run(:initialize_logger) do |config|
  config.log_path = File.join(Restore::Config.log_dir, 'restore.log')
end.configuration

default_config_file = config_file = Pathname.new("#{RAILS_ROOT}/config/lighttpd.conf").cleanpath

require 'optparse'

detach = false
command_line_port = nil

ARGV.options do |opt|
  opt.on("-p", "--port=port", "Changes the server.port number in the config/lighttpd.conf") { |port| command_line_port = port }
  opt.on('-c', "--config=#{config_file}", 'Specify a different lighttpd config file.') { |path| config_file = path }
  opt.on('-h', '--help', 'Show this message.') { puts opt; exit 0 }
  opt.on('-d', '-d', 'Call with -d to detach') { detach = true}
  opt.parse!
end

unless File.exist?(config_file)
  if config_file != default_config_file
    puts "=> #{config_file} not found."
    exit 1
  end

  require 'fileutils'

  source = File.expand_path(File.join(File.dirname(__FILE__),
     "..", "..", "..", "vendor", "rails", "railties", "configs", "lighttpd.conf"))
  puts "=> #{config_file} not found, copying from #{source}"

  FileUtils.cp(source, config_file)
end

# open the config/lighttpd.conf file and add the current user defined port setting to it
if command_line_port
  File.open(config_file, 'r+') do |config|
    lines = config.readlines

    lines.each do |line|
      line.gsub!(/^\s*server.port\s*=\s*(\d+)/, "server.port = #{command_line_port}")
    end

    config.rewind
    config.print(lines)
    config.truncate(config.pos)
  end
end

config = IO.read(config_file)
default_port, default_ip = 3000, '0.0.0.0'
port = config.scan(/^\s*server.port\s*=\s*(\d+)/).first rescue default_port
ip   = config.scan(/^\s*server.bind\s*=\s*"([^"]+)"/).first rescue default_ip
puts "=> Rails application starting on http://#{ip || default_ip}:#{port || default_port}" unless detach

tail_thread = nil

def tail(log_file)
  cursor = File.size(log_file)
  last_checked = Time.now
  tail_thread = Thread.new do
    File.open(log_file, 'r') do |f|
      loop do
        f.seek cursor
        if f.mtime > last_checked
          last_checked = f.mtime
          contents = f.read
          cursor += contents.length
          print contents
        end
        sleep 1
      end
    end
  end
  tail_thread
end

if !detach
  puts "=> Call with -d to detach"
  puts "=> Ctrl-C to shutdown server (see config/lighttpd.conf for options)"
  detach = false
  tail_thread = tail(configuration.log_path)
end

juggernaut_thread = Thread.new do
  require 'juggernaut_server'
  $LOG = Logger.new(File.join(Restore::Config.log_dir, 'restore.log')) if ENV["RESTORE_ENV"] != 'production'
  Juggernaut::Debug.send("Starting Juggernaut Push Server\nPort: #{Juggernaut::CONFIG['PUSH_PORT']}\nHost: #{Juggernaut::CONFIG['PUSH_HOST']}")
  EventMachine::run {
    EventMachine::start_server Juggernaut::CONFIG['PUSH_HOST'], Juggernaut::CONFIG['PUSH_PORT'].to_i, Juggernaut::PushServer
  }
end



trap(:INT) { exit }

begin
  juggernaut_thread unless detach
  `rake tmp:sockets:clear` # Needed if lighttpd crashes or otherwise leaves FCGI sockets around
  `#{lighttpd} #{detach ? '': '-D '}-f #{Pathname.new(config_file).realpath}`
ensure
  unless detach
    juggernaut_thread.kill if juggernaut_thread
    tail_thread.kill if tail_thread
    puts 'Exiting'
  
    # Ensure FCGI processes are reaped
    silence_stream(STDOUT) do
      ARGV.replace ['-a', 'kill']
      require 'commands/process/reaper'
    end
    `rake tmp:sockets:clear` # Remove sockets on clean shutdown
  end
end
