
module Micron
  class Reporter

    def start_tests(files)
    end

    def start_file(test_file)
    end

    def start_class(clazz)
    end

    def add_method(method)
    end

    def end_class(clazz)
    end

    def end_file(test_file)
    end

    def end_tests(files)
    end

  end
end

require "micron/reporter/console"
require "micron/reporter/coverage"
