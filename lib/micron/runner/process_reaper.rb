
module Micron
  class Runner
    class ProcessReaper

      extend Debug

      def self.create(test)
        Thread.new(test) { |test|

          Thread.current[:name] = "reaper-#{test.pid}"
          debug "started"

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
                debug "Unleash the reaper!!"
                Process.kill(9, test.pid)
                break
              end

              if !open then
                if IO.select([test.err], nil, nil, 1).nil? then
                  sel += 1
                  debug "select = #{sel}"
                  # if sel > 3 then
                  #   # thread dead??
                  #   debug "not ready yet?! Unleash the reaper!! #{test.pid}"
                  #   Process.kill(9, test.pid)
                  #   break
                  # end
                  err += 1 if err > 0
                  debug "err = #{err}"
                  Thread.pass
                  next
                end
                debug "opened err io"
                open = true
              end

              str = test.err.read_nonblock(1024*16)
              debug str if !str.nil?
              if !str.nil? &&
                (str.include?("malloc: *** error for object") ||
                 str.include?("Segmentation fault")) then

                debug "looks like we got an error"
                err = 1
              end

            rescue EOFError
              debug "caught EOFError"
              err = 1
              # see if it exited
              if test.wait_nonblock then
                # exited, we're all good..
                debug "hang watcher exiting since it looks like process exited also"
                break
              end

            rescue Errno::EWOULDBLOCK
              # debug "would block?!"
              open = false
              next

            rescue Exception => ex
              debug "caught another ex?!"
              debug Micron.dump_ex(ex, true)
              err = 1

            end

            if err > 0 then
              err += 1
              sleep 0.1
            end

          end

          reapers.delete(Thread.current)
          debug "thread exiting"
        }

      end

    end
  end
end
