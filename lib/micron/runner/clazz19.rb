
module Micron
  class Runner
    class Clazz

      private

      # Compat fix for Ruby 1.9.x
      def name_to_const

        names = name.split('::')
        names.shift if names.empty? || names.first.empty?

        constant = Module
        names.each do |name|
          constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
        end

        return constant
      end

    end
  end
end
