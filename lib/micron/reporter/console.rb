
require "colorize"

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
        duration = sprintf("%0.3f", m.total_duration)

        status = m.status.upcase

        str = ralign(indent(name), "#{duration} #{status}")

        # inject color after so we don't screw up the alignment
        if m.skipped? then
          str.gsub!(/#{status}$/, status.colorize(:light_yellow))
        elsif m.passed? then
          str.gsub!(/#{status}$/, status.colorize(:light_green))
        else
          str.gsub!(/#{status}$/, status.colorize(:light_red))
        end
        puts str

        if m.failed? and !m.skipped? then

          puts
          puts indent(underline("Exception:"))
          puts indent(Micron.dump_ex(m.ex, true))
          puts

          if not m.stdout.empty? then
            puts indent(underline("STDOUT:"))
            puts indent(m.stdout.rstrip)
            puts
          end

          if not m.stderr.empty? then
            puts indent(underline("STDERR:"))
            puts indent(m.stderr.rstrip)
            puts
          end

        end
      end

      def end_class(clazz)
        puts
      end

      def end_tests(files, results)

        total = pass = fail = skip = 0
        total_duration = 0.0
        total_assertions = 0

        results.each { |c|
          c.methods.each { |m|
            total += 1
            total_duration += m.total_duration
            total_assertions += m.assertions
            if m.skipped? then
              skip += 1
            elsif m.passed? then
              pass += 1
            else
              fail += 1
            end
          }
        }

        total_duration = sprintf("%0.3f", total_duration)

        puts
        puts ("="*CONSOLE_WIDTH).colorize((fail > 0 ? :light_red : :light_green))
        puts "  PASS: #{pass},  FAIL: #{fail},  SKIP: #{skip}"
        puts "  TOTAL: #{total} with #{total_assertions} assertions in #{total_duration} seconds"

        if fail > 0 then
          puts
          puts "  Failed tests:"
          results.each { |c|
            c.methods.each { |m|
              if !m.skipped? and m.failed? then
                puts "    #{c.name}##{m.name}"
              end
            }
          }
        end
        puts ("="*CONSOLE_WIDTH).colorize((fail > 0 ? :light_red : :light_green))
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
        i = (" "*amount)
        (i + str.gsub(/\n/, "\n#{i}")).rstrip
      end

      def underline(str)
        str += "\n" + "-"*str.length
      end

    end
  end
end
