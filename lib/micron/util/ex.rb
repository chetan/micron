
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
        s = "<#{ex.class}> #{ex.message}"
        if include_backtrace then
          s += "\n  " + filter_backtrace(ex.backtrace).join("\n  ")
        end
        return s
      end

    end
  end
end
