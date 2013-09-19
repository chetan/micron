
require "parallel"

module Micron
  class Runner

    # A Clazz implementation which forks before running each test method
    class ForkingClazz < Clazz

      def run
        results = Parallel.map(methods, :in_processes => Parallel.processor_count) do |method|
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
