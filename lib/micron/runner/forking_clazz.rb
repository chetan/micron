
require "parallel"

module Micron
  class Runner
    class ForkingClazz < Clazz

      def run
        results = Parallel.map(methods, :in_processes => 8) do |method|
          EasyCov.start
          method.run
          method
        end
        @methods = results
      end

    end
  end
end
