
require "timeout"

module Micron
  class Runner
    class LivenessChecker

      class Ping

        include Debug

        attr_reader :thread

        def initialize(reader, writer, worker)
          @thread = Thread.new(reader, writer, worker) { |reader, writer, worker|

            Thread.current[:name] = "pinger-#{worker.pid}"
            last_pong = Hitimes::Interval.now

            begin
              writer.sync = true

              while true
                writer.puts "ping"
                debug "sent ping"

                begin

                  reply = Timeout.timeout(0.1) { reader.readline }

                  if "pong\n" == reply then
                    last_pong = Hitimes::Interval.now
                    debug "got a pong before timeout"
                  end

                rescue Exception => ex
                  debug "no pong received"
                  if last_pong.to_f > 5.0 then
                    debug "no pong in #{last_pong.to_f} sec! Unleash the reaper!!"
                    Process.kill(9, worker.pid)
                    break
                  end
                end

                sleep 0.1
              end

            rescue => ex
              debug "caught: #{Micron.dump_ex(ex)}"
            end

            debug "ping thread exiting"
          }
        end

      end # Ping

    end
  end
end
