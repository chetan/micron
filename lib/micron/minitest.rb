
# Compatibility layer for MiniTest

require "micron"

module MiniTest
  Assertion = Micron::Assertion

  class Unit

    VERSION = "4.7"
    TestCase = Micron::TestCase

    def self.autorun
      # noop
    end

    class TestCase

      def name
        self.class.name
      end
      alias_method :__name__, :name

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
