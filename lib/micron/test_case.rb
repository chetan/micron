
require "micron/test_case/assertions"
require "micron/test_case/lifecycle_hooks"

module Micron

  class TestCase

    include LifecycleHooks
    include Assertions

    # Run before all test methods in the class
    def self.before_class
    end

    # Run after all test methods in the class
    def self.after_class
    end

    # Run before each test method
    def setup
    end

    # Run after each test method
    def teardown
    end

    # retrieve all loaded subclasses of this class
    #
    # @return [Array<Class>] List of subclasses
    def self.subclasses
      @subclasses
    end

    def self.inherited(subclass)
      if superclass.respond_to? :inherited
        superclass.inherited(subclass)
      end
      @subclasses ||= []
      @subclasses << subclass
    end

  end

end
