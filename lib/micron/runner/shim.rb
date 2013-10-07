
require "tempfile"

module Micron
  class Runner
    class Shim

      # Create a temp shim path
      def self.setup

        ruby_path = `which ruby`.strip
        shim = <<-EOF
#!#{ruby_path}

if ENV["BUNDLE_GEMFILE"] then
  require "bundler"
  Bundler.setup(:default, :development)
end

require "easycov"

EasyCov.path = ENV["EASYCOV_PATH"]
EasyCov.filters << EasyCov::IGNORE_GEMS << EasyCov::IGNORE_STDLIB
EasyCov.start
EasyCov.install_exit_hook()

script = ARGV.shift
$0 = script
require script
EOF

        @shim_dir = Dir.mktmpdir("micron-shim-")
        file = File.join(@shim_dir, "ruby")
        File.open(file, 'w') do |f|
          f.write(shim)
        end
        File.chmod(0777, file)
        EasyCov::Filters.stdlib_paths # make sure this gets cached in env

      end # setup

      # Clean up any existing shim dirs. This should be called only when the
      # master process exists (i.e. Micron::App)
      def self.cleanup!
        # return
        Dir.glob(File.join(Dir.tmpdir, "micron-shim-*")).each do |d|
          FileUtils.rm_rf(d)
        end
      end

      # Wrap the given call with our shim PATH. Any calls to ruby will be
      # redirected to our script to enable coverage collection.
      def self.wrap(&block)
        # enable shim
        ENV["EASYCOV_PATH"] = EasyCov.path
        old_path = ENV["PATH"]
        ENV["PATH"] = "#{@shim_dir}:#{old_path}"

        # call orig method
        block.call()

        # disable shim
        ENV["PATH"] = old_path
      end

    end
  end
end
