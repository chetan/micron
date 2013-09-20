
require "thwait"

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
            hang_watchers << Thread.new(test) { |test|

              Thread.current[:name] = "hang_watcher: #{test.pid}"
              puts "watching #{test.pid} for hangs"

              err = 0
              sel = 0
              open = false
              while true

                begin

                  if err > 10 then # should wait about 3 sec for the proc to exit
                    puts "Unleash the reaper!! #{test.pid}"
                    Process.kill(9, test.pid)
                    break
                  end

                  if !open then
                    if IO.select([test.err], nil, nil, 1).nil? then
                      sel += 1
                      if sel > 10 then
                        # thread dead??
                        puts "not ready yet?! Unleash the reaper!! #{test.pid}"
                        Process.kill(9, test.pid)
                        break
                      end
                      err += 1 if err > 0
                      Thread.pass
                      next
                    end
                    open = true
                  end

                  str = test.err.read_nonblock(1024*16)
                  p str if !str.nil?
                  if !str.nil? &&
                    (str.include?("malloc: *** error for object") ||
                     str.include?("[BUG] Segmentation fault")) then

                    puts "looks like we got an error in test #{test.pid}"
                    # puts str
                    err = 1
                  end

                rescue EOFError
                  puts "caught EOFError for thread #{test.pid}"
                  err = 1
                  # see if it exited
                  if test.wait_nonblock then
                    # exited, we're all good..
                    puts "hang watcher exiting since it looks like process exited also"
                    break
                  end

                rescue Errno::EWOULDBLOCK
                  # puts "would block?!"
                  open = false
                  next

                rescue Exception => ex
                  puts "caught another ex?!"
                  puts ex.inspect
                  ptus ex.backtrace
                  err = 1

                end

                if err > 0 then
                  err += 1
                  sleep 0.1
                end

              end

              hang_watchers.delete(Thread.current)
              puts "hang_watcher thread exiting #{test.pid}"
            }

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

