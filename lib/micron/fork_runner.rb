
module Micron

  class ForkRunner

    def run
      report(:start_tests, @files)

      @files.each do |file|

        # fork for each file
        worker = ForkWorker.new(nil, false) {
          $0 = "micron: class"
          # ERR.puts "micron: class (#{$$})"

          test_file = TestFile.new(file)
          report(:start_file, test_file)

          begin
            test_file.collect_coverage()
            test_file.load()
            results = test_file.run(ForkingClazz)
          rescue Exception => ex
            results = [ex]
          end

          results
        }.run

        results = worker.wait.result
        results.each do |clazz|
          if clazz.kind_of? Exception then
            puts "Error loading test file: #{file}"
            puts clazz
            puts clazz.backtrace
            exit 1
          end

          # should be a Clazz
          @results << clazz
        end

      end

      report(:end_tests, @files, @results)
    end

  end # ForkRunner
end # Micron
