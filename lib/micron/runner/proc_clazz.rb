
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

      # Because we fork exec, we can't just read the back from a pipe. Instead,
      # the child process dumps it to a file and we load it from there.
      #
      # @param [ForkWorker] test
      #
      # @return [Method]
      def collect_result(test)
        results = []
        data_file = File.join(ENV["MICRON_PATH"], "#{test.pid}.data")

        File.open(data_file) do |f|
          while !f.eof
            results << Marshal.load(f) # read Method from child via file
          end
        end
        File.delete(data_file)

        return results.first # should always be just one
      end

    end
  end
end
