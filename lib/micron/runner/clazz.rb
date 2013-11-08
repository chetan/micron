
module Micron
  class Runner
    class Clazz

      include Debug

      attr_reader :name, :methods

      def initialize(clazz, file, method_patterns)
        @name = clazz.to_s
        @file = file
        @methods = test_methods(method_patterns).map { |m| Method.new(self, m) }
      end

      # Create a new instance of the Class represented by this object
      def create
        name_to_const.new
      end

      def run
        methods.each do |method|
          Micron.runner.report(:start_method, method)
          method.run
          Micron.runner.report(:end_method, method)
        end
      end


      private

      # Get all test methods in the TestCase, optionally matching the given
      # patterns
      #
      # @param [Array<String>] patterns       list of patterns to filter by
      #
      # @return [Array<Symbol>] methods
      def test_methods(patterns=[])
        return @test_methods if !@test_methods.nil?

        @test_methods = create.public_methods.find_all { |m|
          m.to_s =~ /^test_/
        }

        if !(patterns.nil? or patterns.empty?) then
          # filter
          @test_methods.reject!{ |m|
            patterns.find{ |t| m.to_s.include?(t.to_s) }.nil?
          }
        end

        @test_methods
      end

      # Convert the @name to a Constant
      #
      # Ruby 2.0+ correctly handles module namespaces while older versions do
      # not. See clazz19.rb for the workaround (included at bottom).
      def name_to_const
        Module.const_get(name)
      end

    end
  end
end

require "micron/runner/clazz19" if RUBY_VERSION =~ /1.9/
