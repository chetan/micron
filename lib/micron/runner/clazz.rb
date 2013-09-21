
module Micron
  class Runner
    class Clazz

      include Debug

      attr_reader :name, :methods

      def initialize(clazz)
        @name = clazz.to_s
        @methods = test_methods.map { |m| Method.new(self, m) }
      end

      # Create a new instance of the Class represented by this object
      def create
        Object.const_get(name).new
      end

      def run
        methods.each do |method|
          method.run
        end
      end


      private

      def test_methods
        create.public_methods.find_all { |m|
          m.to_s =~ /^test_/
        }
      end

    end
  end
end
