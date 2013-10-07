
module Micron
  class Runner
    class TestFile

      def initialize(filename)
        @filename = filename
      end

      # Load the test file
      #
      # @throws [Exception] exception, if one was raised during loading
      def load(coverage=false)
        if coverage then
          file = @filename
          EasyCov.filters << lambda { |f| f == file }
          EasyCov.start
        end
        require @filename
        return nil
      end

      # Simply load the file and collect coverage
      def collect_coverage
        worker = ForkWorker.new do
          load(true)
          EasyCov.dump
        end
        worker.run
        worker.wait
      end

      # Execute the tests in the file, using the given Clazz
      #
      # @param [Clazz] run_clazz
      #
      # @return [Array<Object>] array of Clazz and Exception objects
      def run(run_clazz)

        results = []
        test_clazz = TestCase.subclasses.last

        begin
          clazz = run_clazz.new(test_clazz, @filename)
          if clazz.methods.empty? then
            raise NoMethodError, "#{test_clazz.to_s} has no test methods"
          end

          Micron.runner.report(:start_class, clazz)
          clazz.run
          results << clazz
          Micron.runner.report(:end_class, clazz)

        rescue Exception => ex
          # Error with loading the test class itself
          results << ex
          return results
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
        clazz = run_clazz.new(test_clazz, @filename)
        method = clazz.methods.find{ |m| m.name.to_s == test_method }
        method.run

        return method
      end

    end # TestFile
  end # Runner
end # Micron
