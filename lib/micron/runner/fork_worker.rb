
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
          begin
            @out.last.close
          rescue
          end
          begin
          @err.last.close
          rescue
          end
          begin
          @child_write.close
          rescue
          end
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


      # When a new process is started with chef, it shares the file
      # descriptors of the parent. We clean the file descriptors
      # coming from the parent to prevent unintended locking if parent
      # is killed.
      # NOTE: After some discussions we've decided to iterate on file
      # descriptors upto 256. We believe this  is a reasonable upper
      # limit in a chef environment. If we have issues in the future this
      # number could be made to be configurable or updated based on
      # the ulimit based on platform.
      def clean_parent_file_descriptors
        # Don't clean $stdin, $stdout, $stderr, process_status_pipe.
        keep = [ @child_write.to_i, @out.last.to_i, @err.last.to_i ]
        keep += @liveness_checker.fds if @liveness_checker

        3.upto(256) do |n|
          # We are checking the fd for error pipe before attempting to
          # create a file because error pipe will auto close when we
          # try to create a file since it's set to CLOEXEC.
          if !keep.include? n then
            begin
              fd = File.for_fd(n)
              fd.close if fd
            rescue
            end
          end
        end
      end


    end
  end
end

