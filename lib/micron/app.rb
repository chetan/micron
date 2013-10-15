
require "micron"
require "micron/app/options"

require "fileutils"

module Micron
  class App

    def run(options=nil)
      $0 = "micron: runner"
      Thread.current[:name] = "main thread"

      STDOUT.sync = true
      STDERR.sync = true
      Micron.trap_thread_dump()
      Micron::Runner::Shim.setup

      options = Options.parse(options)

      ENV["PARALLEL_EASYCOV"] = "1"
      if !options[:coverage] then
        ENV["DISABLE_EASYCOV"] = "1"
      end

      # Setup paths
      # TODO allow setting path/root some other way
      path = options.delete(:path)
      path = File.expand_path(Dir.pwd)
      ENV["MICRON_PATH"] = File.join(path, ".micron")
      FileUtils.mkdir_p(ENV["MICRON_PATH"])

      test_paths = []
      %w{test .test}.each do |t|
        t = File.join(path, t)
        if File.directory?(t) then
          $: << t
          test_paths << t
        end
      end

      # Setup reporters
      reporters = []
      reporters << Reporter::Console.new

      # Spawn child runner if called
      if options[:runclass] then
        require "micron/proc_runner"
        methods = ENV["MICRON_METHODS"].split(/:/)
        Micron.runner = Micron::ProcRunner.new(nil, methods, reporters)
        Micron.runner.run_class
        exit
      elsif options[:runmethod] then
        require "micron/proc_runner"
        Micron.runner = Micron::ProcRunner.new(nil, nil, reporters)
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
          if File.file? f then
            files << File.expand_path(f)
          elsif File.directory? f then
            files += find_tests(File.expand_path(f))
          end
        end
      end
      files.flatten!

      if files.empty? then
        files = []
        test_paths.each{ |t| files += find_tests(t) }
      end

      files.sort!

      # Optionally filter files
      if options[:tests] and !options[:tests].empty? then
        files.reject!{ |f|
          options[:tests].find{ |t| f.include?(t) }.nil?
        }
      end

      # Run tests
      if options[:proc] then
        require "micron/proc_runner"
        runner = Micron::ProcRunner
      elsif options[:fork] then
        require "micron/fork_runner"
        runner = Micron::ForkRunner
      else
        runner = Micron::Runner
      end

      Micron.runner = runner.new(files, options[:methods], reporters)
      results = Micron.runner.run

      Micron::Runner::Shim.cleanup!

      # set a non-zero exit code if we had any failures
      exit(count_failures(results) > 0 ? 1 : 0)
    end


    private

    def find_tests(path)
      Dir.glob(File.join(path, "**/*.rb")).find_all { |f|
        f = File.basename(f)
        f =~ /^(test_.*|.*_test)\.rb$/
      }
    end

    # Count the number of failures in the list of results
    #
    # @param [Array<Clazz>] results
    #
    # @return [Fixnum]
    def count_failures(results)
      fail = 0
      results.each { |c|
        c.methods.each { |m|
          fail += 1 if !m.skipped? && !m.passed?
        }
      }
      return fail
    end

  end
end
