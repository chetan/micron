
require "micron/runner/liveness_checker/ping"
require "micron/runner/liveness_checker/pong"

module Micron
  class Runner

    class LivenessChecker

      include Debug

      def initialize
        @ping = IO.pipe
        @pong = IO.pipe
      end

      def ping(pid)
        @pinger = Ping.new(@pong.first, @ping.last, pid)
        @ping.first.close
        @pong.last.close
      end

      def pong
        @ponger = Pong.new(@ping.first, @pong.last)
        @ping.last.close
        @pong.first.close
      end

      def stop
        @pinger.thread.kill
      end

      def fds
        (@ping + @pong).map { |f| f.to_i }
      end

    end

  end
end
