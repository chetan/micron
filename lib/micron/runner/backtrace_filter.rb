
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
        bt.each do |line|
          break if line =~ /lib\/micron/
          new_bt << line
        end

        new_bt = bt.reject { |line| line =~ /lib\/micron/ } if new_bt.empty?
        new_bt = bt.dup if new_bt.empty?
      else
        new_bt = bt.dup
      end

      new_bt
    end

  end

end
