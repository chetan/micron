
module Micron
  module Util
    module IO

      # Captures $stdout and $stderr into strings:
      #
      #   out, err = capture_io do
      #     puts "Some info"
      #     warn "You did a bad thing"
      #   end
      #
      #   assert_match %r%info%, out
      #   assert_match %r%bad%, err
      #
      # NOTE: For efficiency, this method uses StringIO and does not
      # capture IO for subprocesses. Use #capture_subprocess_io for
      # that.
      def capture_io
        require 'stringio'

        captured_stdout, captured_stderr = StringIO.new, StringIO.new

        # synchronize do
          orig_stdout, orig_stderr = $stdout, $stderr
          $stdout, $stderr         = captured_stdout, captured_stderr

          begin
            yield
          ensure
            $stdout = orig_stdout
            $stderr = orig_stderr
          end

        # end

        return captured_stdout.string, captured_stderr.string
      end

      # Dispose of STDOUT/STDERR
      #
      # @param [Array<IO>] out
      # @param [Array<IO>] err
      def dispose_io(out, err)
        STDOUT.reopen out.last
        out.last.close
        STDERR.reopen err.last
        err.last.close
        STDOUT.sync = STDERR.sync = true
      end

    end
  end
end
