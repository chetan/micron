
require "thwait"

require "micron/runner/process_reaper"

module Micron
  class Runner

    # Base class for parallel Clazz implementations
    class ParallelClazz < Clazz

      def run
        # spawn tests in separate processes
        tests = []
        debug "spawning #{methods.size} methods"
        methods.each do |method|
          tests << spawn_test(method)
        end

        # wait for all test methods to return
        finished = wait_for_tests(tests)

        # collect results
        @methods = collect_results(finished)
        debug "collected #{@methods.size} methods"
      end


      private

      # Wait for all test processes to complete, rerunning failures if needed
      def wait_for_tests(tests)

        # OUT.puts "waiting for tests"

        finished = []
        watchers = []
        hang_watchers = []

        test_queue = Queue.new
        tests.each { |t| test_queue.push(t) }

        meta_watcher = Thread.new {
          # thread which will make sure we're watching all tests, including
          # any that get respawned
          Thread.current[:name] = "meta_watcher"

          while true
            test = test_queue.pop # blocking
            debug "creating watcher for #{test.pid}"

            watchers << Thread.new(test) { |test|
              Thread.current[:name] = "watcher-#{test.pid}"
              debug "start"

              while true
                begin
                  status = test.wait2.to_i
                  # puts "process #{test.pid} exited with status #{status}"

                  if status == 0 then
                    finished << test

                  elsif status == 6 || status == 4 || status == 9 then
                    # segfault/coredump due to coverage
                    # puts "process #{test.pid} returned error"
                    method = test.context
                    test_queue << spawn_test(method) # new watcher thread will be spawned
                    debug "respawned failed test: #{method.clazz.name}##{method.name}"

                  else
                    puts
                    puts "== UNKNOWN ERROR! =="
                    puts "STATUS: #{status}"
                    puts "STDERR:"
                    puts f.stderr
                    puts "STDOUT:"
                    puts f.stdout
                    exit 3

                  end

                rescue Errno::ECHILD
                  debug "retrying wait2"
                  next # retry - should get cached status

                rescue Exception => ex
                  debug "caught: #{Micron.dump_ex(ex)}"
                end

                break # break loop by default
              end


              debug "exit thread"
              watchers.delete(Thread.current)
            }

            # create another thread to make sure the process didn't hang after
            # throwing an error on stderr
            hang_watchers << ProcessReaper.create(test)
          end

          debug "exiting"
        }

        while !watchers.empty? || !test_queue.empty?
          watchers.reject!{ |w| !w.alive? } # prune dead threads
          ThreadsWait.all_waits(*watchers)
        end
        debug "all watcher threads finished for #{self.name}"
        meta_watcher.kill
        hang_watchers.each{ |t| t.kill }

        return finished
      end

    end

  end
end

