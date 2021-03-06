
module Micron
  class Runner

    # A Clazz implementation which forks before running each test method
    class ForkingClazz < ParallelClazz

      private

      def spawn_test(method)
        ForkWorker.new(method) {
          $0 = "micron: method"
          # ERR.puts "#{$0} (#{$$})"

          EasyCov.start

          Shim.wrap {
            method.run
          }

          method
        }.run(true)
      end

      # Collect the result data
      #
      # @param [Array] finished       Completed pids & their associated methods
      #
      # @return [Array<Method>]
      def collect_results(finished)
        finished.map{ |f| collect_result(f) }
      end

      def collect_result(worker)
        worker.result
      end

    end
  end
end
