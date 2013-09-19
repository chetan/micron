
module Micron
  class Runner
    class TestFile

      def initialize(filename)
        @filename = filename
      end

      # Execute the tests in the file
      def run

        results = []

        begin
          EasyCov.start
          require @filename
        rescue => ex
          results << ex
          return results
        end

        TestCase.subclasses.each do |clazz|
          # should really only be one per file..
          begin
            # clazz = Clazz.new(clazz)
            clazz = ForkingClazz.new(clazz)
            if !clazz.methods.empty? then
              clazz.run
              results << clazz
            end

          rescue Exception => ex
            # Error with loading the test class itself
            results << ex
            return results
          end
        end

        return results
      end

    end # TestFile
  end # Runner
end # Micron
