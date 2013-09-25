
require 'optparse'

module Micron
  class App
    class Options

      DEFAULTS = {
        :coverage => true
      }

      def self.parse(options=nil)

        # always try to use default options first
        if options then
          options = DEFAULTS.merge(options)
        else
          options = DEFAULTS.dup
        end

        # then rc file
        rc = File.join(Dir.pwd, ".micronrc")
        if File.exists? rc then
          parse_opts(options, File.read(rc).split(" "))
        end

        # then anything on command line
        parse_opts(options, ARGV)

        return options
      end

      def self.parse_opts(options, argv)
        parser = OptionParser.new do |opts|
          opts.banner = "usage: #{$0} [options]"

          opts.on("--nocov", "Disable coverage reporting") {
            options[:coverage] = false
          }

          opts.on("--proc", "Use the process runner") {
            options[:proc] = true
          }

          opts.on("--fork", "Use the forking runner") {
            options[:fork] = true
          }

          opts.on("--runclass", "Run class in child process") {
            options[:runclass] = true
          }

          opts.on("--runmethod", "Run method in child process") {
            options[:runmethod] = true
          }
        end

        begin
          parser.parse!(argv)

        rescue Exception => ex
          exit if ex.kind_of? SystemExit
          STDERR.puts "error: #{ex}"
          STDERR.puts
          STDERR.puts parser
          exit 1
        end

        return options
      end # self.parse_opts
    end
  end
end
