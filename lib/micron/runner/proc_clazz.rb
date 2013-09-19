
require "parallel"

module Micron
  class Runner

    # A Clazz implementation which will fork/exec before running each test method
    class ProcClazz < Clazz

      def run

        results = [] # result methods
        methods.each do |method|

          # fork/exec once per method, synchronously
          ENV["MICRON_TEST_CLASS"] = method.clazz.name
          ENV["MICRON_TEST_METHOD"] = method.name.to_s

          pid = fork do
            exec("bundle exec micron --runmethod")
          end
          Process.wait

          # read result method
          data_file = File.join(ENV["MICRON_PATH"], "#{pid}.data")
          File.open(data_file) do |f|
            while !f.eof
              results << Marshal.load(f) # read Method from child via file
            end
          end
          File.delete(data_file)

          # ERR.puts "bailing early for now (after one method)"
          # break

        end

        @methods = results
      end

    end
  end
end
