
module Micron
  class Runner
    module Debug

      def debug(str)

        return

        name = Thread.current[:name] || ""
        if !name.empty? then
          name = "[#{name} #{$$}] "
        else
          name = "[#{$$}]"
        end

        puts "#{name} #{str}"
      end

    end
  end
end
