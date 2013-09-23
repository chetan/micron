
module Micron
  module Util
    module ThreadDump

      # Setup thread dump signal
      def trap_thread_dump
        # print a thread dump on SIGALRM
        # kill -ALRM <pid>
        Signal.trap 'SIGALRM' do
          File.open(File.join(ENV["MICRON_PATH"], "#{$$}.threads.txt"), "w+") do |f|
            f.puts
            f.puts "=== micron thread dump: #{Time.now} ==="
            f.puts
            Thread.list.each do |thread|
              f.puts "Thread-#{thread.object_id}" + (thread[:name] ? ": " + thread[:name] : "")
              f.puts thread.backtrace.join("\n    \\_ ")
              f.puts "-"
              f.puts
            end
            f.puts "=== end micron thread dump ==="
            f.puts
          end
        end
      end

    end
  end
end
