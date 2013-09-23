
require "easycov"

require "micron/util/io"
require "micron/util/thread_dump"
require "micron/util/ex"

require "micron/assertion"
require "micron/test_case"
require "micron/runner"

module Micron

  extend Micron::Util::IO
  extend Micron::Util::ThreadDump
  extend Micron::Util::Ex

  class << self

    attr_accessor :backtrace_filter

    def filter_backtrace(bt)
      backtrace_filter.call(bt)
    end

  end # self
  self.backtrace_filter = BacktraceFilter.new # default filter

end
