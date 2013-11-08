
module Micron
  class Runner
    class TestFile

      def initialize(filename, method_patterns)
        @filename        = filename
        @method_patterns = method_patterns
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

        # run before_class
        begin
          test_clazz.before_class
        rescue Exception => ex
          # skip rest of class on error
          return skip_all_tests(test_clazz, ex)
        end

        begin
          clazz = run_clazz.new(test_clazz, @filename, @method_patterns)

          Micron.runner.report(:start_class, clazz)
          if !clazz.methods.empty? then
            clazz.run
            results << clazz
          end

          # run after_class
          begin
            test_clazz.after_class
          rescue Exception => ex
            Micron.runner.report(:after_class_error, ex)
          end

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


      private

      # Mark all tests as skipped due to some error
      def skip_all_tests(test_clazz, ex)
        results = []
        clazz = Clazz.new(test_clazz, @filename, @method_patterns)

        Micron.runner.report(:start_class, clazz)
        Micron.runner.report(:before_class_error, ex)

        if !clazz.methods.empty? then
          clazz.methods.each do |method|
            method.ex = Micron::Skip.new("before_class failed")
            Micron.runner.report(:end_method, method)
          end
          results << clazz
        end

        Micron.runner.report(:end_class, clazz)

        results
      end

    end # TestFile
  end # Runner
end # Micron
