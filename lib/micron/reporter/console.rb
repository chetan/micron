
require "ansi"

module Micron
  class Reporter
    class Console < Reporter

      CONSOLE_WIDTH = 100

      def start_tests(files)
        @runtime = Hitimes::Interval.now
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
          str.gsub!(/#{status}$/, colorize(status, :yellow))
        elsif m.passed? then
          str.gsub!(/#{status}$/, colorize(status, :green))
        else
          str.gsub!(/#{status}$/, colorize(status, :red))
        end
        puts str

        if m.failed? and !m.skipped? then

          puts
          puts indent(underline("Exception:"))
          if m.ex.kind_of? Array then
            m.ex.each{ |ex|
              next if m.ex.nil?
              puts indent(Micron.dump_ex(ex, true))
              puts
            }
          elsif m.ex.nil? then
            puts indent("nil")
            puts
          else
            puts indent(Micron.dump_ex(m.ex, true))
            puts
          end

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

        @runtime.stop

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
        real_runtime = sprintf("%0.3f", @runtime.duration)

        puts
        puts divider(fail > 0 ? :red : (skip > 0 ? :yellow : :green))
        puts "  PASS: #{pass},  FAIL: #{fail},  SKIP: #{skip}"
        puts "  TOTAL: #{total} with #{total_assertions} assertions in #{total_duration} seconds (wall time: #{real_runtime})"

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
        puts divider(fail > 0 ? :red : (skip > 0 ? :yellow : :green))
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

      # Add an underline to the given string
      #
      # @param [String] str       string to underline
      #
      # @return [String] underlined string
      def underline(str)
        str += "\n" + "-"*str.length
      end

      # Draw a divider CONSOLE_WIDTH chars wide in the given color
      def divider(color)
        colorize(("="*CONSOLE_WIDTH), color)
      end

      def colorize(str, color, bold=true)
        ret  = ANSI.reset
        ret += ANSI.bold if bold
        ret += ANSI.send(color)
        ret += str
        ret += ANSI.reset
        ret
      end

    end
  end
end
