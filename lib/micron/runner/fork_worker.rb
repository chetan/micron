
require "micron/runner/debug"
require "micron/runner/liveness_checker"

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

      include Debug

      CHUNK_SIZE = 1024 * 16

      attr_reader :pid, :context, :status

      def initialize(context=nil, capture_stdout=true, capture_stderr=true, &block)
        @context        = context
        @capture_stdout = capture_stdout
        @capture_stderr = capture_stderr
        @block          = block
        @done           = false
      end

      def run(check_liveness=false)
        @out, @err = IO.pipe, IO.pipe
        @parent_read, @child_write = IO.pipe
        @child_write.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

        @liveness_checker = LivenessChecker.new if check_liveness

        @pid = fork do

          Thread.current[:name] = "worker"
          Micron.trap_thread_dump()

          # close unused readers in child
          @out.first.close
          @err.first.close
          @parent_read.close

          # redirect io
          STDOUT.reopen(@out.last) if @capture_stdout
          STDERR.reopen(@err.last) if @capture_stderr
          STDOUT.sync = STDERR.sync = true

          clean_parent_file_descriptors()

          @liveness_checker.pong if check_liveness

          # run
          debug("calling block")
          ret = @block.call()
          debug("block returned")

          # Pass result to parent via pipe
          Marshal.dump(ret, @child_write)
          @child_write.flush
          debug("wrote result to pipe")

          # cleanup
          @out.last.close
          @err.last.close
          @child_write.close
        end

        # close unused writers in parent
        @out.last.close
        @err.last.close
        @child_write.close

        @liveness_checker.ping(self) if check_liveness

        self
      end

      # Blocking wait for process to finish
      #
      # @return [self]
      def wait
        return self if @done

        Process.wait(@pid)
        @done = true
        @status = $?
        @liveness_checker.stop if @liveness_checker
        self
      end

      # Blocking wait for process to finish
      #
      # @return [Process::Status]
      def wait2
        return @status if @done

        pid, @status = Process.wait2(@pid)
        @done = true
        @liveness_checker.stop if @liveness_checker
        return @status
      end

      # Non-blocking wait for process to finish
      #
      # @return [Process::Status] nil if not yet complete
      def wait_nonblock
        return @status if @done

        pid, @status = Process.waitpid2(@pid, Process::WNOHANG)
        if !@status.nil? then
          @done = true
          @liveness_checker.stop if @liveness_checker
        end
        return @status
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

      def out
        @out.first
      end

      def err
        @err.first
      end


      private


      # Cleanup all FDs inherited from the parent. We don't need them and we
      # may throw errors if they are left open. 8192 should be high enough.
      def clean_parent_file_descriptors
        # Don't clean $stdin, $stdout, $stderr (0-2) or our own pipes
        keep = [ @child_write.to_i, @out.last.to_i, @err.last.to_i ]
        keep += @liveness_checker.fds if @liveness_checker

        3.upto(8192) do |n|
          if !keep.include? n then
            begin
              fd = IO.for_fd(n)
              fd.close if fd
            rescue
            end
          end
        end
      end


    end
  end
end

