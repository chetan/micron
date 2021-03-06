
require "micron/runner/parallel_clazz"
require "micron/runner/fork_worker"
require "micron/runner/proc_clazz"
require "micron/test_case/teardown_coverage"

module Micron
  class ProcRunner < Runner

    def initialize(files=nil, method_patterns=nil, reporters=nil)
      super(files, method_patterns, reporters)
    end

    def run
      $0 = "micron: proc_runner"
      # ERR.puts "#{$0} (#{$$})"

      state_path = ENV["MICRON_PATH"]
      FileUtils.mkdir_p(state_path)

      report(:start_tests, @files)
      @files.each do |file|

        ENV["MICRON_TEST_FILE"] = file
        pid = fork do
          exec("bundle exec micron --runclass")
        end
        Process.wait

        # puts "got stdout: #{cmd.stdout}"
        # puts "got stderr: #{cmd.stderr}"
        # puts "status: #{cmd.status}"
        # puts "exitstatus: #{cmd.exitstatus.inspect}"

        data_file = File.join(state_path, "#{pid}.data")
        File.open(data_file) do |f|
          while !f.eof
            clazz = Marshal.load(f) # read Clazz from child via file
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
        File.delete(data_file)

      end

      report(:end_tests, @files, @results)

      return @results
    end # run


    # Child process which runs an entire test file/class
    def run_class
      $0 = "micron:proc_run_class"
      # ERR.puts "micron: proc_run_class (#{$$})"

      test_file = TestFile.new(test_filename)
      report(:start_file, test_file)

      begin
        test_file.load(false)
        results = test_file.run(ProcClazz)
      rescue Exception => ex
        results = [ex]
      end

      # pass data back to parent process
      data_file = File.join(ENV["MICRON_PATH"], "#{$$}.data")
      File.open(data_file, "w") do |f|
        results.each { |r| Marshal.dump(r, f) }
      end
    end

    # Child process which runs a single method in a given file & class
    def run_method
      $0 = "micron:proc_run_method"
      # ERR.puts "#{$0} (#{$$})"

      test_clazz = ENV["MICRON_TEST_CLASS"]
      test_method = ENV["MICRON_TEST_METHOD"]

      # ERR.puts "test_clazz: #{test_clazz}"
      # ERR.puts "test_method: #{test_method}"

      test_file = TestFile.new(test_filename)
      test_file.load(true)
      # load and run a specific method only
      result = test_file.run_method(test_clazz, test_method, Clazz)

      # pass data back to parent process
      data_file = File.join(ENV["MICRON_PATH"], "#{$$}.data")
      File.open(data_file, "w") do |f|
        Marshal.dump(result, f)
      end
    end


    private

    def test_filename
      ENV["MICRON_TEST_FILE"]
    end


  end
end
