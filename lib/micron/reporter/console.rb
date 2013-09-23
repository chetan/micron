
module Micron
  class Reporter
    class Console < Reporter

      CONSOLE_WIDTH = 100

      def start_tests(files)
        puts "="*CONSOLE_WIDTH
        puts ralign("START TESTS (#{files.size} files)", "#{Time.new}")
        puts "="*CONSOLE_WIDTH
        puts
      end

      def start_class(clazz)
        puts clazz.name
      end

      def end_method(m)
        name = m.name.to_s
        duration = sprintf("%0.4f", m.total_duration)
        puts ralign(indent(name), "#{duration} #{m.status.upcase}")
        if m.failed? and !m.skipped? then
          puts "  <#{m.ex.name}> #{m.ex.message}"
          puts "    " + Micron.filter_backtrace(m.ex.backtrace).join("\n    ")
          puts
          puts m.stdout
          puts m.stderr
        end
      rescue Exception => ex
        puts ex
      end

      def end_class(clazz)
        puts
      end

      def end_tests(files, results)

        total = pass = fail = skip = 0
        total_duration = 0.0

        results.each { |c|
          c.methods.each { |m|
            total += 1
            total_duration += m.total_duration
            if m.skipped? then
              skip += 1
            elsif m.passed? then
              pass += 1
            else
              fail += 1
            end
          }
        }

        total_duration = sprintf("%0.4f", total_duration)

        puts
        puts "="*CONSOLE_WIDTH
        puts "  PASS: #{pass},  FAIL: #{fail},  SKIP: #{skip}"
        puts "  TOTAL: #{total} with - assertions in #{total_duration}"
        puts "="*CONSOLE_WIDTH
      end


      private

      # Right align 'b' with padding after a
      #
      # e.g.:
      # a <padding> b
      def ralign(a, b, length=CONSOLE_WIDTH)
        p = length-a.length-b.length
        a + (" "*p) + b
      end

      # Indent the string by the given amount
      def indent(str, amount=2)
        (" "*amount) + str
      end

    end
  end
end
