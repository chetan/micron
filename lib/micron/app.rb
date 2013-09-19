
require "micron"
require "micron/app/options"

module Micron
  class App

    def run
      $0 = "micron: runner"

      trap_thread_dump()

      options = Options.parse

      if !options[:coverage] then
        ENV["DISABLE_EASYCOV"] = "1"
      end

      # Setup paths
      # TODO allow setting path/root some other way
      path = File.expand_path(Dir.pwd)
      ENV["MICRON_PATH"] = File.join(path, ".micron")

      %w{test .test}.each do |t|
        t = File.join(path, t)
        $: << t if File.directory?(t)
      end

      # Spawn child runner if called
      if options[:runclass] then
        require "micron/proc_runner"
        ProcRunner.new.run_class
        exit
      elsif options[:runmethod] then
        require "micron/proc_runner"
        ProcRunner.new.run_method
        exit
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
        Micron::ProcRunner.new(files).run
      else
        Micron::Runner.new(files).run
      end

      # coverage report
      if options[:coverage] then
        generate_coverage_report(path)
      end
    end

    def generate_coverage_report(path)
      # Locate easycov path used in tests
      %w{coverage .coverage}.each do |t|
        t = File.join(path, t)
        if File.directory?(t) && File.exists?(File.join(t, ".resultset.json")) then
          EasyCov.path = t
        end
      end

      # Write coverage
      SimpleCov::ResultMerger.merged_result.format!
    end

    # Setup thread dump signal
    def trap_thread_dump
      # print a thread dump on SIGALRM
      # kill -ALRM <pid>
      Signal.trap 'SIGALRM' do
        File.open(File.join(ENV["MICRON_PATH"], "#{$$}.threads.txt"), "w+") do |f|
          f.puts
          f.puts "=== micron thread dump: #{Time.now} ==="
          f.puts
          Thread.list.each do |thread|
            f.puts "Thread-#{thread.object_id}"
            f.puts thread.backtrace.join("\n    \\_ ")
            f.puts "-"
            f.puts
          end
          f.puts "=== end micron thread dump ==="
          f.puts
        end
      end
    end

  end
end
