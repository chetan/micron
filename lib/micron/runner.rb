
require "micron/runner/backtrace_filter"

require "micron/runner/test_file"
require "micron/runner/clazz"
require "micron/runner/method"
require "micron/runner/exception_info"

require "micron/runner/parallel_clazz"
require "micron/runner/fork_worker"
require "micron/runner/forking_clazz"

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

    def initialize(files)
      @files = files
      @results = []
    end

    def run
      run_all_tests()
    end


    def display_results

      puts "Finished all tests"
      puts

      results.each do |clazz|
        display_result(result)
      end

    end

    def display_result(clazz)
      puts "#{clazz.name} ->"
      clazz.methods.each do |m|
        puts "  #{m.name}: (#{m.status}) #{m.total_duration}"
        if m.failed? and !m.skipped? then
          puts "  <#{m.ex.name}> #{m.ex.message}"
          puts "    " + Micron.filter_backtrace(m.ex.backtrace).join("\n    ")
          puts
          puts m.stdout
          puts m.stderr
        end
      end
    end

    def run_all_tests
      @files.each do |file|

        # fork for each file
        worker = ForkWorker.new {
          $0 = "micron: class"
          # ERR.puts "micron: class (#{$$})"

          test_file = TestFile.new(file)
          begin
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
          add_result(clazz)
        end

      end
    end

    # Add a new result Clazz
    def add_result(clazz)
      @results << clazz
      display_result(clazz)
    end

  end

end
