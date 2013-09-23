
module Micron
  module Util
    module Ex

      # Utility method for converting Exceptions to Strings
      #
      # @param [Exception] ex
      # @param [Boolean] include_backtrace
      #
      # @return [String]
      def dump_ex(ex, include_backtrace=false)
        name = ex.respond_to?(:name) ? ex.name : ex.class.to_s
        s = "<#{name}> #{ex.message}"
        if include_backtrace then
          s += "\n  " + filter_backtrace(ex.backtrace).join("\n  ")
        end
        return s
      end

    end
  end
end
