
# Compatibility layer for MiniTest

module MiniTest
  Assertion = Micron::Assertion

  module Unit

    VERSION = "4.7"
    TestCase = Micron::TestCase

    class TestCase

      def micron_method=(method)
        @micron_method = method
      end

      def passed?
        @micron_method.passed?
      end

      def self.parallelize_me!
        # noop
      end

    end

  end
end
