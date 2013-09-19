
require "lockfile"

module Micron
  class Runner

    # A Clazz implementation which will fork/exec before running each test method
    class ProcClazz < Clazz

      def run

        results = [] # result methods
        tests = []

        # spawn tests in separate processes
        methods.each do |method|
          tests << spawn_test(method)
        end


        # wait for all test methods to return
        finished = []
        while !tests.empty?
          tests.each do |test|
            pid, status = Process.waitpid2(test[:pid], Process::WNOHANG)
            if !status.nil?
              puts "process #{pid} exited with status #{status.to_i}"

              if status.to_i == 0 then
                finished << tests.delete(test)

              else
                puts "process returned error, forcing unlock"
                force_unlock(pid)
                test = tests.delete(test)
                method = test[:method]
                puts "respawning failed test: #{method.clazz.name}##{method.name}"
                tests << spawn_test(method)
              end
            end

            sleep 0.01
          end
        end

        # make sure all locks are cleared, in case there were any errors/coredumps
        # force_sweep()
        # force_unlock()

        # collect results
        finished.each do |test|

          data_file = File.join(ENV["MICRON_PATH"], "#{test[:pid]}.data")

          # File is missing if the process crashed (coverage bug)
          # we can always try again, perhaps??
          next if not File.exists? data_file

          File.open(data_file) do |f|
            while !f.eof
              results << Marshal.load(f) # read Method from child via file
            end
          end
          File.delete(data_file)
        end

        @methods = results
      end


      private

      def spawn_test(method)
        # fork/exec once per method, synchronously
        ENV["MICRON_TEST_CLASS"] = method.clazz.name
        ENV["MICRON_TEST_METHOD"] = method.name.to_s

        out, err = IO.pipe, IO.pipe
        pid = fork do
          # throw away stdout/err
          STDOUT.reopen out.last
          out.last.close
          STDERR.reopen err.last
          err.last.close
          STDOUT.sync = STDERR.sync = true
          exec("bundle exec micron --runmethod")
        end

        { :pid => pid, :method => method }
      end

      def force_sweep
        puts "sweeping.."
        %w{coverage .coverage}.each { |cov_dir|
          file = File.join(Dir.pwd, cov_dir, ".lockfile")
          next if !File.exists? file

          begin
            Lockfile.new(file).sweep
          rescue
          end
        }
      end

      def force_unlock(pid)
        puts "force unlocking #{pid}"

        %w{coverage .coverage}.each { |cov_dir|
          file = File.join(Dir.pwd, cov_dir, ".lockfile")
          next if !File.exists? file

          pidline = File.readlines(file).find { |l| l =~ /^pid:/ }
          if pid == pidline.split(/:/).last.strip.to_i then
            puts "found the pid in the lockfile.. deleting!"
            File.delete(file)
          end

          # begin
          #   Lockfile.new(file).unlock
          # rescue
          # end
        }
      end

    end
  end
end
