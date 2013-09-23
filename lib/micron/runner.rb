
require "micron/runner/backtrace_filter"
require "micron/runner/debug"

require "micron/runner/test_file"
require "micron/runner/clazz"
require "micron/runner/method"
require "micron/runner/exception_info"

require "micron/runner/parallel_clazz"
require "micron/runner/fork_worker"
require "micron/runner/forking_clazz"

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

    attr_reader :results

    def initialize(files, reporters)
      @files     = files
      @results   = []
      @reporters = reporters || []

      @mutex = Mutex.new
    end

    def run
      report(:start_tests, @files)

      @files.each do |file|

        # fork for each file
        worker = ForkWorker.new(nil, false) {
          $0 = "micron: class"
          # ERR.puts "micron: class (#{$$})"

          test_file = TestFile.new(file)
          report(:start_file, test_file)

          begin
            test_file.collect_coverage()
            test_file.load()
            results = test_file.run(ForkingClazz)
          rescue Exception => ex
            results = [ex]
          end

          results
        }.run

        results = worker.wait.result
        results.each do |clazz|
          if clazz.kind_of? Exception then
            puts "Error loading test file: #{file}"
            puts clazz
            puts clazz.backtrace
            exit 1
          end

          # should be a Clazz
          @results << clazz
        end

      end

      report(:end_tests, @files, @results)
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

    def synchronize(&block)
      @mutex.synchronize(&block)
    end

  end # Runner
end # Micron
