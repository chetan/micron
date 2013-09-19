
module Micron
  class Runner

    # Fork Worker
    #
    # @example
    #   fw = Micron::Runner::ForkWorker.new do
    #     system("ls")
    #     "sup"
    #   end
    #   fw.run.wait
    #   puts fw.stdout
    #   puts fw.result # => sup
    #
    class ForkWorker

      attr_reader :pid, :context

      def initialize(context=nil, &block)
        @context = context
        @block = block
        @done = false
      end

      def run
        @out, @err = IO.pipe, IO.pipe
        @parent_read, @child_write = IO.pipe

        @pid = fork do

          Micron.trap_thread_dump()

          # close unused readers in child
          @out.first.close
          @err.first.close
          @parent_read.close

          # redirect io
          STDOUT.reopen @out.last
          STDERR.reopen @err.last
          STDOUT.sync = STDERR.sync = true

          # run
          ret = @block.call()

          # Pass result to parent via pipe
          Marshal.dump(ret, @child_write)

          # cleanup
          @out.last.close
          @err.last.close
          @child_write.close
        end

        # close unused writers in parent
        @out.last.close
        @err.last.close
        @child_write.close

        self
      end

      # Blocking wait for process to finish
      #
      # @return [self]
      def wait
        # old0 = $0
        # $0 = "#{$0} (waiting for #{@pid})"
        Process.wait(@pid)
        # $0 = old0
        @done = true
        self
      end

      # Non-blocking wait for process to finish
      #
      # @return [Process::Status] nil if not yet complete
      def wait_nonblock
        pid, status = Process.waitpid2(@pid, Process::WNOHANG)
        if !status.nil? then
          @done = true
        end
        return status
      end

      def result
        if !@done then
          wait()
        end
        @result = Marshal.load(@parent_read)
        @parent_read.close
        @result
      end

      def stdout
        return @stdout if !@stdout.nil?
        @stdout = @out.first.read
        @out.first.close
        @stdout ||= ""
        @stdout
      end

      def stderr
        return @stderr if !@stderr.nil?
        @stderr = @err.first.read
        @err.first.close
        @stderr ||= ""
        @stderr
      end

    end
  end
end

