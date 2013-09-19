
require 'optparse'

module Micron
  class App
    class Options
      def self.parse

        options = {
          :coverage => true
        }

        parser = OptionParser.new do |opts|
          opts.banner = "usage: #{$0} [options]"

          opts.on("--nocov", "Disable coverage reporting") {
            options[:coverage] = false
          }

          opts.on("--proc", "Use process runner") {
            options[:proc] = true
          }

          opts.on("--runproc", "Run child process") {
            options[:runproc] = true
          }
        end

        begin
          parser.parse!
        rescue Exception => ex
          exit if ex.kind_of? SystemExit
          STDERR.puts "error: #{ex}"
          STDERR.puts
          STDERR.puts parser
          exit 1
        end

        return options

      end # self.parse
    end
  end
end
