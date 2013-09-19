
module Micron
  class Runner
    class TestFile

      def initialize(filename)
        @filename = filename
      end

      # Load the test file
      #
      # @throws [Exception] exception, if one was raised during loading
      def load
        EasyCov.start
        require @filename
        return nil
      end

      # Execute the tests in the file, using the given Clazz
      #
      # @param [Clazz] run_clazz
      #
      # @return [Array<Object>] array of Clazz and Exception objects
      def run(run_clazz)

        results = []

        TestCase.subclasses.each do |test_clazz|
          # should really only be one per file..
          begin
            clazz = run_clazz.new(test_clazz)
            if clazz.methods.empty? then
              next
            end

            clazz.run
            results << clazz

          rescue Exception => ex
            # Error with loading the test class itself
            results << ex
            return results
          end
        end

        return results
      end

      # Run the given test method
      #
      # @param [String] test_clazz       Name of the TestCase Class
      # @param [String] test_method      Method name
      # @param [Clazz] run_clazz         Clazz to run with
      #
      # @return [Method]
      def run_method(test_clazz, test_method, run_clazz)
        clazz = run_clazz.new(Module.const_get(test_clazz))
        method = clazz.methods.find{ |m| m.name.to_s == test_method }
        method.run

        return method
      end

    end # TestFile
  end # Runner
end # Micron
