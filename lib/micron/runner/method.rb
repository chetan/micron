
require 'hitimes'

module Micron
  class Runner
    class Method

      attr_reader :clazz, :name, :durations
      attr_accessor :passed, :ex
      attr_reader :stdout, :stderr

      def initialize(clazz, name)
        @passed    = false
        @durations = {}

        @clazz     = clazz
        @name      = name
      end

      def run
        out, err = Micron.capture_io {
          run_test()
        }
        @stdout = out
        @stderr = err
        nil
      end

      # Execute the actual test
      def run_test
        t = nil

        begin
          t = clazz.create
          if t.respond_to? :micron_method= then
            t.micron_method = self # minitest compat shim
          end

          time(:setup)   { setup(t) }

          time(:runtime) { t.send(name) }
          self.passed = true

        rescue *PASSTHROUGH_EXCEPTIONS
          raise

        rescue Exception => e
          self.passed = false
          self.ex     = ExceptionInfo.new(e)

        ensure
          time(:teardown) {
            teardown(t) if not t.nil?
          }
        end
      end

      def passed?
        passed
      end

      def skipped?
        ex.kind_of?(Skip)
      end

      def failed?
        !passed
      end

      def status
        if skipped? then
          "skip"
        elsif passed? then
          "pass"
        else
          "fail"
        end
      end

      # Get the total duration of this method's run (setup + runtime + teardown)
      def total_duration
        n = 0.0
        @durations.values.each{ |d| n += d }
        n
      end


      private

      # Time the given block of code and enter it into the log
      def time(name, &block)
        @durations[name] = Hitimes::Interval.measure(&block)
      end

      # Call setup methods
      def setup(t)
        t.before_setup
        t.setup
        t.after_setup
      end

      # Call teardown methods
      def teardown(t)
        %w{before_teardown teardown after_teardown}.each do |hook|
          begin
            t.send(hook)
          rescue *PASSTHROUGH_EXCEPTIONS
            raise
          rescue Exception => e
            self.passed = false
            self.ex     = ExceptionInfo.new(e)
          end
        end
      end

    end
  end
end
