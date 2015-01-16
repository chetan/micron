
module Micron
  class Reporter

    # Reporter which generates coverage report using SimpleCov
    class Coverage < Reporter

      def end_tests(files, results)
        generate_coverage_report()
      end


      private

      def generate_coverage_report
        path = File.dirname(ENV["MICRON_PATH"])

        # Locate easycov path used in tests
        %w{coverage .coverage}.each do |t|
          t = File.join(path, t)
          if File.directory?(t) && !Dir.glob(File.join(t, ".tmp.*.resultset.json")).empty? then
            EasyCov.path = t
          end
        end

        # Merge coverage
        EasyCov.merge!

        if !ENV["MICRON_NO_HTML"] then
          # Write coverage
          Micron.capture_io {
            SimpleCov::ResultMerger.merged_result.format!
          }
        end
      end

    end
  end
end
