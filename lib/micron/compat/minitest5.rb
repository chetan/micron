
# Compatibility layer for MiniTest

require "micron"

old_verbose = $VERBOSE
$VERBOSE = nil

module Minitest

  Assertion = Micron::Assertion

  VERSION = "5.3.3"
  Test = Micron::TestCase

  def self.autorun
    # noop
  end

  class Test

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

    def self.i_suck_and_my_tests_are_order_dependent!
      # noop
    end

  end

end

$VERBOSE = old_verbose
