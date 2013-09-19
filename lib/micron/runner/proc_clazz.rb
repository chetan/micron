
require "parallel"

module Micron
  class Runner

    # A Clazz implementation which will fork/exec before running each test method
    class ProcClazz < Clazz

      def run

        results = [] # result methods
        tests = []

        methods.each do |method|
          # fork/exec once per method, synchronously
          ENV["MICRON_TEST_CLASS"] = method.clazz.name
          ENV["MICRON_TEST_METHOD"] = method.name.to_s

          pid = fork do
            exec("bundle exec micron --runmethod")
          end

          tests << { :pid => pid, :method => method }
        end

        Process.waitall # wait for all test methods to return

        # collect results
        tests.each do |test|

          data_file = File.join(ENV["MICRON_PATH"], "#{test[:pid]}.data")

          # File is missing if the process crashed (coverage bug)
          # we can always try again, perhaps??
          next if not File.exists? data_file

          File.open(data_file) do |f|
            while !f.eof
              results << Marshal.load(f) # read Method from child via file
            end
          end
          File.delete(data_file)
        end

        @methods = results
      end

    end
  end
end
