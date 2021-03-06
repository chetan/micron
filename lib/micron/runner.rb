
require "micron/runner/shim"

require "micron/runner/backtrace_filter"
require "micron/runner/debug"

require "micron/runner/test_file"
require "micron/runner/clazz"
require "micron/runner/method"
require "micron/runner/exception_info"

require "micron/reporter"

module Micron

  # Default Runner - forks for each file
  class Runner

    OUT = $stdout
    ERR = $stderr

    # these exceptions, if caught while running, will be re-raised
    PASSTHROUGH_EXCEPTIONS = [
      NoMemoryError, SignalException, Interrupt, SystemExit
    ]

    attr_reader :results, :reporters, :files

    def initialize(files, method_patterns, reporters)
      @files           = files
      @method_patterns = method_patterns || []
      @reporters       = reporters || []
      @results         = []

      @mutex = Mutex.new

      if self.class.to_s != "Micron::Runner" then
        # Only needed in fork/proc runners
        TestCase.class_eval do
          include TestCase::TeardownCoverage
        end
      end
    end

    def run
      report(:start_tests, @files)

      @files.each do |file|

        test_file = TestFile.new(file, @method_patterns)
        report(:start_file, test_file)

        begin
          test_file.load(true)
          results = test_file.run(Clazz)
        rescue Exception => ex
          results = [ex]
        end

        results.each do |clazz|
          if clazz.kind_of? Exception then
            STDERR.puts "Error loading test file: #{file}"
            STDERR.puts clazz
            STDERR.puts clazz.backtrace
            exit 1
          end

          # should be a Clazz
          @results << clazz
        end

      end

      EasyCov.dump
      report(:end_tests, @files, @results)

      return @results
    end

    # Fire the given report event on all reporters
    #
    # @param [Symbol] method
    # @param [*args]
    def report(method, *args)
      synchronize {
        @reporters.each { |r| r.send(method, *args) }
      }
    end

    # Output synchronization helper. Will NOT work across forks!
    def synchronize(&block)
      @mutex.synchronize(&block)
    end

  end # Runner
end # Micron
