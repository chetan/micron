
require "micron/test_case/assertions"
require "micron/test_case/lifecycle_hooks"

module Micron

  class TestCase

    include LifecycleHooks
    include Assertions

    def setup
    end

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
