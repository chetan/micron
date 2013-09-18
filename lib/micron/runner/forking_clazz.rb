
require "parallel"

module Micron
  class Runner

    # A Clazz implementation which forks before running each test method
    class ForkingClazz < Clazz

      def run
        results = Parallel.map(methods, :in_processes => 8) do |method|
          $0 = "micron: method"
          EasyCov.start
          method.run
          method
        end
        @methods = results
      end

    end
  end
end
