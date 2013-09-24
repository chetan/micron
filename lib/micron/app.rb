
require "micron"
require "micron/app/options"

require "fileutils"

module Micron
  class App

    def run
      $0 = "micron: runner"
      Thread.current[:name] = "main thread"

      STDOUT.sync = true
      STDERR.sync = true
      Micron.trap_thread_dump()

      options = Options.parse

      ENV["PARALLEL_EASYCOV"] = "1"
      if !options[:coverage] then
        ENV["DISABLE_EASYCOV"] = "1"
      end

      # Setup paths
      # TODO allow setting path/root some other way
      path = File.expand_path(Dir.pwd)
      ENV["MICRON_PATH"] = File.join(path, ".micron")
      FileUtils.mkdir_p(ENV["MICRON_PATH"])

      %w{test .test}.each do |t|
        t = File.join(path, t)
        $: << t if File.directory?(t)
      end

      # Setup reporters
      reporters = []
      reporters << Reporter::Console.new

      # Spawn child runner if called
      if options[:runclass] then
        require "micron/proc_runner"
        Micron.runner = Micron::ProcRunner.new(nil, reporters)
        Micron.runner.run_class
        exit
      elsif options[:runmethod] then
        require "micron/proc_runner"
        Micron.runner = Micron::ProcRunner.new(nil, reporters)
        Micron.runner.run_method
        exit
      end

      # Add coverage reporter
      if options[:coverage] then
        reporters.unshift Reporter::Coverage.new
      end

      # Find tests to run
      files = []
      if not ARGV.empty? then
        ARGV.each do |f|
          if File.exists? f then
            files << File.expand_path(f)
          end
        end
      end

      if files.empty? then
        files = Dir.glob(File.join(path, "**/*.rb")).find_all { |f|
          f = File.basename(f)
          f =~ /^(test_.*|.*_test)\.rb$/
        }
      end

      # Run tests
      if options[:proc] then
        require "micron/proc_runner"
        Micron.runner = Micron::ProcRunner.new(files, reporters)
      elsif options[:fork] then
        require "micron/fork_runner"
        Micron.runner = Micron::ForkRunner.new(files, reporters)
      else
        Micron.runner = Micron::Runner.new(files, reporters)
      end
      Micron.runner.run

    end

  end
end
