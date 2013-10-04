
require "logging"

module Micron
  class TestCase
    module RedirLogging

      # Send logging to stdout for duration of test
      def before_setup
        super
        logger = self.class.redir_logger
        return if logger.nil?

        @_old_log_appenders = logger.appenders
        @_old_log_additive  = logger.additive
        @_old_log_level     = logger.level

        logger.clear_appenders
        logger.additive = false
        logger.level    = :debug

        # add original appenders which do not point to stdout, and our custom
        # $stdout appender
        logger.add_appenders(@_old_log_appenders.reject{ |a| a.kind_of? Logging::Appenders::Stdout })
        logger.add_appenders("stdout_test")
      end

      # Restore appenders
      def after_teardown
        super
        logger = self.class.redir_logger
        return if logger.nil?
        logger.clear_appenders
        logger.add_appenders(@_old_log_appenders)
        logger.additive = @_old_log_additive
        logger.level    = @_old_log_level
      end

      def self.included(receiver)
        receiver.extend(ClassMethods)
      end

      module ClassMethods
        attr_writer :redir_logger

        # Search up the TestCase hierarchy for a redir_logger
        def redir_logger
          return @redir_logger if !@redir_logger.nil?
          return superclass.redir_logger if superclass.respond_to? :redir_logger
          nil
        end
      end

    end
  end
end

# A simple subclass of the Stdout appender which writes to whatever
# $stdout is currently pointing to
module Logging::Appenders
  class StdoutTest < Stdout
    def canonical_write( str )
      return self if @io.nil?
      str = str.force_encoding(encoding) if encoding and str.encoding != encoding
      # STDOUT.puts "writing log to $stdout: #{str}"
      # STDOUT.puts "$stdout is currently #{$stdout.inspect}"
      $stdout.syswrite str
      self
    rescue StandardError => err
      self.level = :off
      ::Logging.log_internal {"appender #{name.inspect} has been disabled"}
      ::Logging.log_internal(-2) {err}
    end
  end
end

# Configure test appender
Logging::Appenders::StdoutTest.new( 'stdout_test',
  :auto_flushing => true,
  :layout => Logging.layouts.pattern(
    :pattern => '%.1l, [%d] %5l -- %c: %m\n',
    :color_scheme => 'bright'
  )
)

