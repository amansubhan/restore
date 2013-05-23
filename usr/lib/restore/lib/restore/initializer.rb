require 'logger'
require 'set'
#require File.join(File.dirname(__FILE__), 'railties_path')
#require File.join(File.dirname(__FILE__), 'rails/version')

RESTORE_ENV = (ENV['RESTORE_ENV'] || 'development').dup unless defined?(RESTORE_ENV)

module Restore
  # The Initializer is responsible for processing the Rails configuration, such
  # as setting the $LOAD_PATH, requiring the right frameworks, initializing
  # logging, and more. It can be run either as a single command that'll just
  # use the default configuration, like this:
  #
  #   Rails::Initializer.run
  #
  # But normally it's more interesting to pass in a custom configuration
  # through the block running:
  #
  #   Rails::Initializer.run do |config|
  #     config.frameworks -= [ :action_web_service ]
  #   end
  #
  # This will use the default configuration options from Rails::Configuration,
  # but allow for overwriting on select areas.
  require 'gettext'
  include GetText
  
  
  class Initializer
    # The Configuration instance used by this Initializer instance.
    attr_reader :configuration

    # Runs the initializer. By default, this will invoke the #process method,
    # which simply executes all of the initialization routines. Alternately,
    # you can specify explicitly which initialization routine you want:
    #
    #   Rails::Initializer.run(:set_load_path)
    #
    # This is useful if you only want the load path initialized, without
    # incuring the overhead of completely loading the entire environment.
    def self.run(command = :process, configuration = Configuration.new)
      yield configuration if block_given?
      initializer = new configuration
      initializer.send(command)
      initializer
    end

    # Create a new Initializer instance that references the given Configuration
    # instance.
    def initialize(configuration)
      @configuration = configuration
      @loaded_plugins = []
    end

    # Sequentially step through all of the available initialization routines,
    # in order:
    #
    # * #set_load_path
    # * #set_connection_adapters
    # * #require_frameworks
    # * #load_environment
    # * #initialize_database
    # * #initialize_logger
    # * #initialize_framework_logging
    # * #initialize_framework_views
    # * #initialize_dependency_mechanism
    # * #initialize_breakpoints
    # * #initialize_whiny_nils
    # * #initialize_framework_settings
    # * #load_environment
    # * #load_plugins
    # * #load_observers
    # * #initialize_routing
    #
    # (Note that #load_environment is invoked twice, once at the start and
    # once at the end, to support the legacy configuration style where the
    # environment could overwrite the defaults directly, instead of via the
    # Configuration instance.
    def process
      set_load_path

      require_frameworks
      set_autoload_paths
      load_environment

      initialize_database
      initialize_logger
      initialize_framework_logging
      initialize_dependency_mechanism
      initialize_framework_settings
      initialize_gettext
      
      # Support for legacy configuration style where the environment
      # could overwrite anything set from the defaults/global through
      # the individual base class configurations.
      load_environment

      # the framework is now fully initialized
      after_initialize
    end

    # Set the <tt>$LOAD_PATH</tt> based on the value of
    # Configuration#load_paths. Duplicates are removed.
    def set_load_path
      load_paths = configuration.load_paths + configuration.framework_paths
      load_paths.reverse_each { |dir| $LOAD_PATH.unshift(dir) if File.directory?(dir) }
      $LOAD_PATH.uniq!
    end

    # Set the paths from which Rails will automatically load source files, and
    # the load_once paths.
    def set_autoload_paths
      Dependencies.load_paths = configuration.load_paths.uniq
      Dependencies.load_once_paths = configuration.load_once_paths.uniq

      extra = Dependencies.load_once_paths - Dependencies.load_paths
      unless extra.empty?
        abort <<-end_error
          load_once_paths must be a subset of the load_paths.
          Extra items in load_once_paths: #{extra * ','}
        end_error
      end

      # Freeze the arrays so future modifications will fail rather than do nothing mysteriously
      configuration.load_once_paths.freeze
    end

    # Requires all frameworks specified by the Configuration#frameworks
    # list. By default, all frameworks (ActiveRecord, ActiveSupport,
    # ActionPack, ActionMailer, and ActionWebService) are loaded.
    def require_frameworks
      configuration.frameworks.each { |framework| require(framework.to_s) }
    end

    # Loads the environment specified by Configuration#environment_path, which
    # is typically one of development, testing, or production.
    def load_environment
      silence_warnings do
        config = configuration
        constants = self.class.constants
        eval(IO.read(configuration.environment_path), binding, configuration.environment_path)
        (self.class.constants - constants).each do |const|
          Object.const_set(const, self.class.const_get(const))
        end
      end
    end

    # This initialization routine does nothing unless <tt>:active_record</tt>
    # is one of the frameworks to load (Configuration#frameworks). If it is,
    # this sets the database configuration from Configuration#database_configuration
    # and then establishes the connection.
    def initialize_database
      return unless configuration.frameworks.include?(:active_record)
      ActiveRecord::Base.configurations = configuration.database_configuration
      ActiveRecord::Base.establish_connection(RESTORE_ENV)
    end

    # If the +RAILS_DEFAULT_LOGGER+ constant is already set, this initialization
    # routine does nothing. If the constant is not set, and Configuration#logger
    # is not +nil+, this also does nothing. Otherwise, a new logger instance
    # is created at Configuration#log_path, with a default log level of
    # Configuration#log_level.
    #
    # If the log could not be created, the log will be set to output to
    # +STDERR+, with a log level of +WARN+.
    def initialize_logger
      # if the environment has explicitly defined a logger, use it
      return if defined?(RAILS_DEFAULT_LOGGER)

      unless logger = configuration.logger
        begin
          logger = Logger.new(configuration.log_path)
          logger.level = Logger.const_get(configuration.log_level.to_s.upcase)
        rescue StandardError
          logger = Logger.new(STDERR)
          logger.level = Logger::WARN
          logger.warn(
            "Rails Error: Unable to access log file. Please ensure that #{configuration.log_path} exists and is chmod 0666. " +
            "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
          )
        end
      end

      silence_warnings { Object.const_set "RAILS_DEFAULT_LOGGER", logger }
    end

    # Sets the logger for ActiveRecord, ActionController, and ActionMailer
    # (but only for those frameworks that are to be loaded). If the framework's
    # logger is already set, it is not changed, otherwise it is set to use
    # +RAILS_DEFAULT_LOGGER+.
    def initialize_framework_logging
      for framework in ([ :active_record, :action_controller, :action_mailer ] & configuration.frameworks)
        framework.to_s.camelize.constantize.const_get("Base").logger ||= RAILS_DEFAULT_LOGGER
      end
    end

    # Sets the dependency loading mechanism based on the value of
    # Configuration#cache_classes.
    def initialize_dependency_mechanism
      Dependencies.mechanism = configuration.cache_classes ? :require : :load
    end

    # Initializes framework-specific settings for each of the loaded frameworks
    # (Configuration#frameworks). The available settings map to the accessors
    # on each of the corresponding Base classes.
    def initialize_framework_settings
      configuration.frameworks.each do |framework|
        base_class = framework.to_s.camelize.constantize.const_get("Base")

        configuration.send(framework).each do |setting, value|
          base_class.send("#{setting}=", value)
        end
      end
    end
    
    def initialize_gettext
      GetText.bindtextdomain("restore", File.join(RESTORE_ROOT, 'locale'))
    end
    
    # Fires the user-supplied after_initialize block (Configuration#after_initialize)
    def after_initialize
      configuration.after_initialize_block.call if configuration.after_initialize_block
    end

  end

  # The Configuration class holds all the parameters for the Initializer and
  # ships with defaults that suites most Rails applications. But it's possible
  # to overwrite everything. Usually, you'll create an Configuration file
  # implicitly through the block running on the Initializer, but it's also
  # possible to create the Configuration instance in advance and pass it in
  # like this:
  #
  #   config = Rails::Configuration.new
  #   Rails::Initializer.run(:process, config)
  class Configuration
    # A stub for setting options on ActionMailer::Base
    attr_accessor :action_mailer

    # A stub for setting options on ActionView::Base
    attr_accessor :action_view

    # A stub for setting options on ActiveRecord::Base
    attr_accessor :active_record

    # Whether or not classes should be cached (set to false if you want
    # application classes to be reloaded on each request)
    attr_accessor :cache_classes

    # The list of connection adapters to load. (By default, all connection
    # adapters are loaded. You can set this to be just the adapter(s) you
    # will use to reduce your application's load time.)
    attr_accessor :connection_adapters

    # The path to the database configuration file to use. (Defaults to
    # <tt>config/database.yml</tt>.)
    attr_accessor :database_configuration_file

    # The list of rails framework components that should be loaded. (Defaults
    # to <tt>:active_record</tt>, <tt>:action_controller</tt>,
    # <tt>:action_view</tt>, <tt>:action_mailer</tt>, and
    # <tt>:action_web_service</tt>).
    attr_accessor :frameworks

    # An array of additional paths to prepend to the load path. By default,
    # all +app+, +lib+, +vendor+ and mock paths are included in this list.
    attr_accessor :load_paths

    # An array of paths from which Rails will automatically load from only once.
    # All elements of this array must also be in +load_paths+.
    attr_accessor :load_once_paths

    # The log level to use for the default Rails logger. In production mode,
    # this defaults to <tt>:info</tt>. In development mode, it defaults to
    # <tt>:debug</tt>.
    attr_accessor :log_level

    # The path to the log file to use. Defaults to log/#{environment}.log
    # (e.g. log/development.log or log/production.log).
    attr_accessor :log_path

    # The specific logger to use. By default, a logger will be created and
    # initialized using #log_path and #log_level, but a programmer may
    # specifically set the logger to use via this accessor and it will be
    # used directly.
    attr_accessor :logger

    # Create a new Configuration instance, initialized with the default
    # values.
    def initialize
      self.frameworks                   = default_frameworks
      self.load_paths                   = default_load_paths
      self.load_once_paths              = default_load_once_paths
      self.log_path                     = default_log_path
      self.log_level                    = default_log_level
      self.cache_classes                = default_cache_classes
      self.database_configuration_file  = default_database_configuration_file

      for framework in default_frameworks
        self.send("#{framework}=", Restore::OrderedOptions.new)
      end
    end

    # Loads and returns the contents of the #database_configuration_file. The
    # contents of the file are processed via ERB before being sent through
    # YAML::load.
    def database_configuration
      YAML::load(ERB.new(IO.read(database_configuration_file)).result)
    end

    # The path to the current environment's file (development.rb, etc.). By
    # default the file is at <tt>config/environments/#{environment}.rb</tt>.
    def environment_path
      "#{root_path}/config/environments/#{environment}.rb"
    end

    # Return the currently selected environment. By default, it returns the
    # value of the +RAILS_ENV+ constant.
    def environment
      ::RESTORE_ENV
    end

    # Sets a block which will be executed after rails has been fully initialized.
    # Useful for per-environment configuration which depends on the framework being
    # fully initialized.
    def after_initialize(&after_initialize_block)
      @after_initialize_block = after_initialize_block
    end

    # Returns the block set in Configuration#after_initialize
    def after_initialize_block
      @after_initialize_block
    end

    def framework_paths
      # TODO: Don't include dirs for frameworks that are not used
      %w(
        activesupport/lib
        activerecord/lib
        actionmailer/lib
      ).map { |dir| "#{framework_root_path}/#{dir}" }.select { |dir| File.directory?(dir) }
    end

    private
      def root_path
        ::RESTORE_ROOT
      end

      def framework_root_path
        defined?(::RAILS_FRAMEWORK_ROOT) ? ::RAILS_FRAMEWORK_ROOT : "#{root_path}/vendor/rails"
      end

      def default_frameworks
        [ :active_record, :action_mailer ]
      end

      def default_load_paths

        # Followed by the standard includes.
        paths = %w(
          config
          lib
          vendor
        ).map { |dir| "#{root_path}/#{dir}" }.select { |dir| File.directory?(dir) }
      end

      # Doesn't matter since plugins aren't in load_paths yet.
      def default_load_once_paths
        []
      end

      def default_log_path
        File.join(root_path, 'log', "#{environment}.log")
      end

      def default_log_level
        environment == 'production' ? :info : :debug
      end

      def default_database_configuration_file
        File.join(root_path, 'config', 'database.yml')
      end


      def default_dependency_mechanism
        :load
      end

      def default_cache_classes
        false
      end
  end
end

# Needs to be duplicated from Active Support since its needed before Active
# Support is available. Here both Options and Hash are namespaced to prevent
# conflicts with other implementations AND with the classes residing in ActiveSupport.
class Restore::OrderedOptions < Array #:nodoc:
  def []=(key, value)
    key = key.to_sym

    if pair = find_pair(key)
      pair.pop
      pair << value
    else
      self << [key, value]
    end
  end

  def [](key)
    pair = find_pair(key.to_sym)
    pair ? pair.last : nil
  end

  def method_missing(name, *args)
    if name.to_s =~ /(.*)=$/
      self[$1.to_sym] = args.first
    else
      self[name]
    end
  end

  private
    def find_pair(key)
      self.each { |i| return i if i.first == key }
      return false
    end
end
