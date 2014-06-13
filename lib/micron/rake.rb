
require "rake/tasklib"

module Micron
  class Rake < ::Rake::TaskLib


    def initialize(&block)
      @config = {
        :path => File.dirname(ENV["BUNDLE_GEMFILE"])
      }
      block.call(@config) if block

      define()
    end

    private

    def define

      desc "Run micron tests"
      task :test do
        require "micron/app"
        ARGV.clear
        Micron::App.new.run(@config)
      end

    end

  end
end
