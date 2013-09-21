
module Micron
  class Runner
    class ProcessReaper

      def self.create(test)
        Thread.new(test) { |test|

          Thread.current[:name] = "hang_watcher: #{test.pid}"
          # puts "watching #{test.pid} for hangs"

          err = 0
          sel = 0
          open = false
          while true

            if test.wait_nonblock then
              # process exited!
              break
            end

            begin

              if err > 10 then # should wait about 3 sec for the proc to exit
                puts "Unleash the reaper!! #{test.pid}"
                Process.kill(9, test.pid)
                break
              end

              if !open then
                if IO.select([test.err], nil, nil, 1).nil? then
                  sel += 1
                  # if sel > 3 then
                  #   # thread dead??
                  #   puts "not ready yet?! Unleash the reaper!! #{test.pid}"
                  #   Process.kill(9, test.pid)
                  #   break
                  # end
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

    end
  end
end
