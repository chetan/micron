
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

      # Execute the tests in the file
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

    end # TestFile
  end # Runner
end # Micron
