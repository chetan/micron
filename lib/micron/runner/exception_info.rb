
module Micron
  class Runner
    class ExceptionInfo

      attr_reader :name, :message, :backtrace

      def initialize(ex)
        @name      = ex.class.to_s
        @message   = ex.message
        @backtrace = ex.backtrace
      end

    end
  end
end
