module Micron
  class Runner
    class LivenessChecker

      class Pong

        include Debug

        attr_reader :thread

        def initialize(reader, writer)
          @thread = Thread.new(reader, writer) { |reader, writer|

            Thread.current[:name] = "ponger"
            debug "thread started"

            begin
              writer.sync = true
              while line = reader.readline
                debug "got ping request, replying"
                writer.puts "pong"
              end

            rescue Exception => ex
              debug "caught error: #{Micron.dump_ex(ex)}"
            end

            debug "thread exiting from #{$$}"
          }
        end

      end # Pong

    end
  end
end
