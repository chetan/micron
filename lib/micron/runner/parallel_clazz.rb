
module Micron
  class Runner

    # Base class for parallel Clazz implementations
    class ParallelClazz < Clazz

      def run
        # spawn tests in separate processes
        tests = []
        methods.each do |method|
          tests << spawn_test(method)
        end

        # wait for all test methods to return
        finished = wait_for_tests(tests)

        # collect results
        @methods = collect_results(finished)
      end


      private

      # Wait for all test processes to complete, rerunning failures if needed
      def wait_for_tests(tests)

        finished = []
        while !tests.empty?
          tests.each do |test|
            status = test.wait_nonblock
            if !status.nil?
              # puts "process #{test.pid} exited with status #{status.to_i}"

              if status.to_i == 0 then
                finished << tests.delete(test)

              elsif status.to_i == 6 then
                # segfault/coredump due to coverage
                # puts "process #{pid} returned error"
                method = tests.delete(test).context
                # puts "respawning failed test: #{method.clazz.name}##{method.name}"
                tests << spawn_test(method)

              else
                puts
                puts "== UNKONWN ERROR! =="
                puts "STATUS: #{status.to_i}"
                puts "STDOUT:"
                p f.stdout
                puts "STDERR:"
                p f.stderr
                exit 3

              end
            end

            sleep 0.01
          end
        end

        return finished
      end

    end

  end
end

