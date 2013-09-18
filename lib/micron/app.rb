
require "micron"

module Micron
  class App

    def run

      $0 = "micron: runner"

      # Setup paths
      path = File.expand_path(Dir.pwd)

      %w{test .test}.each do |t|
        t = File.join(path, t)
        $: << t if File.directory?(t)
      end

      # Find tests to run
      files = Dir.glob(File.join(path, "**/*.rb")).find_all { |f|
        f = File.basename(f)
        f =~ /^(test_.*|.*_test)\.rb$/
      }

      # Run tests
      Micron::Runner.new(files).run

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

  end
end
