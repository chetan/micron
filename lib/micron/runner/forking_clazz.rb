
require "parallel"

module Micron
  class Runner

    # A Clazz implementation which forks before running each test method
    class ForkingClazz < Clazz

      def run
        # num_procs = Parallel.processor_count

        forks = []
        methods.each do |method|
          forks << spawn_test(method)
        end

        # Wait for results from all forks
        results = []
        while !forks.empty?
          forks.each do |f|
            status = f.wait_nonblock
            if !status.nil?
              puts "process #{f.pid} exited with status #{status.to_i}"

              if status.to_i == 0 then
                results << forks.delete(f).result

              elsif status.to_i == 6 then
                # segfault/coredump due to coverage
                puts "process #{f.pid} returned error"
                method = forks.delete(f).context
                puts "respawning failed test: #{method.clazz.name}##{method.name}"
                forks << spawn_test(method)

              else
                puts "hrm... unknown error!"
                puts "status: #{status.to_i}"
                puts "stdout:"
                p f.stdout
                puts "stderr:"
                p f.stderr
                exit 3

              end
            end

            sleep 0.01
          end
        end

        @methods = results
      end


      private

      def spawn_test(method)
        ForkWorker.new(method) {
          $0 = "micron: method"
          ERR.puts "#{$0} (#{$$})"

          EasyCov.start
          method.run
          method
        }.run
      end

    end
  end
end
