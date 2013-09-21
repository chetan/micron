
require "thwait"

require "micron/runner/process_reaper"

module Micron
  class Runner

    # Base class for parallel Clazz implementations
    class ParallelClazz < Clazz

      def run
        # spawn tests in separate processes
        tests = []
        methods.each do |method|
          tests << spawn_test(method)
        end

        # wait for all test methods to return
        finished = wait_for_tests(tests)

        # collect results
        @methods = collect_results(finished)
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
            # puts "creating new watcher for #{test.pid}"

            watchers << Thread.new(test) { |test|
              Thread.current[:name] = "watcher: #{test.pid}"
              # puts "new thread watching test #{test.pid}"
              status = test.wait2.to_i
              # puts "process #{test.pid} exited with status #{status}"

              if status == 0 then
                finished << test

              elsif status == 6 || status == 4 || status == 9 then
                # segfault/coredump due to coverage
                # puts "process #{test.pid} returned error"
                method = test.context
                test_queue << spawn_test(method) # new watcher thread will be spawned
                # puts "respawned failed test: #{method.clazz.name}##{method.name}"

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

              # puts "deleting watcher thread for test #{test.pid}"
              watchers.delete(Thread.current)
            }

            # create another thread to make sure the process didn't hang after
            # throwing an error on stderr
            hang_watchers << ProcessReaper.create(test)

          end

          # puts "meta_watcher exiting"
        }

        while !watchers.empty? || !test_queue.empty?
          watchers.reject!{ |w| !w.alive? } # prune dead threads
          ThreadsWait.all_waits(*watchers)
        end
        # puts "all watcher threads finished"
        meta_watcher.kill
        hang_watchers.each{ |t| t.kill }

        return finished
      end

    end

  end
end

