
require "micron/runner/backtrace_filter"
require "micron/runner/clazz"
require "micron/runner/forking_clazz"
require "micron/runner/method"
require "micron/runner/exception_info"

module Micron

  class Runner

    OUT = $stdout
    ERR = $stderr

    END_OF_STREAM = "end_of_stream"

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
      # display_results()

    end # run


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

        # fork for each process
        r,w = IO.pipe
        pid = fork do
          $0 = "micron: class"
          load_and_run(file, w)
          Marshal.dump(END_OF_STREAM, w) # end of stream marker
        end

        Process.wait

        while true
          clazz = Marshal.load(r) # read Clazz from child via pipe
          if clazz == END_OF_STREAM then
            break # got end of stream marker

          elsif clazz.kind_of? Exception then
            puts "Error loading test file: #{file}"
            puts clazz
            puts clazz.backtrace
            exit 1
          end

          add_result(clazz)
        end
      end
    end

    # Add a new result Clazz
    def add_result(clazz)
      @results << clazz
      display_result(clazz)
    end

    # Load the given test file and run all test classes within
    def load_and_run(file, w)

      begin
        EasyCov.start
        require file
      rescue => ex
        Marshal.dump(ex, w)
        return
      end

      TestCase.subclasses.each do |clazz|
        # should really only be one per file..
        begin
          # clazz = Clazz.new(clazz)
          clazz = ForkingClazz.new(clazz)
          if !clazz.methods.empty? then
            clazz.run
            Marshal.dump(clazz, w) # pass Clazz back to parent via pipe
          end

        rescue Exception => ex
          # Error with the test class itself
          Marshal.dump(ex, w)
          return
        end
      end
    end

  end

end
