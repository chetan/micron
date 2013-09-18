
module Micron

  # Default backtrace filter
  #
  # This can be swapped out by setting Micron::Runner.backtrace_filter
  # to a block, proc, lambda, or a class with a #call method.
  class BacktraceFilter

    def call(bt)
      return ["No backtrace"] unless bt and !bt.empty?

      new_bt = []

      unless $DEBUG then

        if bt.first =~ %r{^/.*?/lib/micron/test_case/assertions.rb:\d+:in} then
          # first line is an assertion, pop it off
          bt.shift
        end

        bt.each do |line|
          break if line =~ %r{(bin|lib)/micron}
          new_bt << line
        end

        # make sure we didn't remove everything - if we did, the error was in our code
        new_bt = bt.reject { |line| line =~ %r{(bin|lib)/micron} } if new_bt.empty?
        new_bt = bt.dup if new_bt.empty?
      else
        new_bt = bt.dup
      end

      new_bt
    end

  end

end
