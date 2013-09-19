
require "mixlib/shellout"

module Micron
  class ProcRunner < Runner

    def initialize(files=nil)
      super(files)
    end

    def run_all_tests

      state_path = ENV["MICRON_PATH"]
      FileUtils.mkdir_p(state_path)

      @files.each do |file|

        ENV["MICRON_TEST_FILE"] = file
        # cmd = Mixlib::ShellOut.new("micron", "--runproc")
        # cmd.run_command
        # pid = cmd.stdout.strip.to_i
        pid = fork do
          exec("micron --runproc")
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
              puts "Error loading test file: #{file}"
              puts clazz
              puts clazz.backtrace
              exit 1
            end

            # should be a Clazz
            add_result(clazz)
          end
        end
        File.delete(data_file)

        # puts "bailing early"
        # exit

      end

    end # run_all_tests

    def run_proc
      $0 = "micron:proc_class"
      ERR.puts "micron: proc class (#{$$})"
      file = ENV["MICRON_TEST_FILE"]

      test_file = TestFile.new(file)
      begin
        test_file.load()
        results = test_file.run(ForkingClazz)
      rescue Exception => ex
        results = [ex]
      end

      data_file = File.join(ENV["MICRON_PATH"], "#{$$}.data")
      File.open(data_file, "w") do |f|
        results.each { |r| Marshal.dump(r, f) }
      end
      STDOUT.puts $$ # return our pid via stdout (shellout hack)
    end


  end
end
