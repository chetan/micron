
module Micron
  class TestCase

    module TeardownCoverage
      def before_teardown
        EasyCov.checkpoint
      end
    end

  end
end
