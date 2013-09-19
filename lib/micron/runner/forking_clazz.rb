
require "parallel"

module Micron
  class Runner

    # A Clazz implementation which forks before running each test method
    class ForkingClazz < Clazz

      def run
        # Parallel.processor_count
        results = Parallel.map(methods, :in_processes => 1) do |method|
          $0 = "micron: method"
          ERR.puts "micron: method (#{$$})"

          EasyCov.start
          method.run
          method
        end
        @methods = results
      end

    end
  end
end
