
module Micron
  class TestCase

    module TeardownCoverage
      def before_teardown
        super
        EasyCov.checkpoint
      end
    end

  end
end
