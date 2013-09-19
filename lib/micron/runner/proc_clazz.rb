
require "lockfile"

module Micron
  class Runner

    # A Clazz implementation which will fork/exec before running each test method
    class ProcClazz < ParallelClazz

      private

      # Spawn a process for the given method
      #
      # @param [Method] method
      # @param [Boolean] dispose_output       If true, throw away stdout/stderr (default: true)
      #
      # @return [Hash]
      def spawn_test(method, dispose_output=true)
        # fork/exec once per method, synchronously
        ENV["MICRON_TEST_CLASS"] = method.clazz.name
        ENV["MICRON_TEST_METHOD"] = method.name.to_s

        ForkWorker.new(method) {
          exec("bundle exec micron --runmethod")
        }.run
      end

      # Collect the result data

      # Because we fork exec, we can't just read the back from a pipe. Instead,
      # the child process dumps it to a file and we load it from there.
      #
      # @param [Array] finished       Completed pids & their associated methods
      #
      # @return [Array<Method>]
      def collect_results(finished)
        results = [] # result methods
        finished.each do |test|

          data_file = File.join(ENV["MICRON_PATH"], "#{test.pid}.data")

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

        return results
      end

    end
  end
end
