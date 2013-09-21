
module Micron
  class Runner
    module Debug

      def debug(str)

        @@mutex ||= Mutex.new

        name = Thread.current[:name] || ""
        if !name.empty? then
          name = "[#{name} #{$$}] "
        else
          name = "[#{$$}]"
        end

        @@mutex.synchronize {
          puts "#{name} #{str}"
        }
      end

    end
  end
end
