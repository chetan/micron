# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: micron 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "micron"
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chetan Sarva"]
  s.date = "2013-09-26"
  s.description = "An extremely minimal unit test library for Ruby"
  s.email = "chetan@pixelcop.net"
  s.executables = ["micron"]
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "Rakefile",
    "VERSION",
    "bin/micron",
    "lib/micron.rb",
    "lib/micron/app.rb",
    "lib/micron/app/options.rb",
    "lib/micron/assertion.rb",
    "lib/micron/fork_runner.rb",
    "lib/micron/minitest.rb",
    "lib/micron/proc_runner.rb",
    "lib/micron/rake.rb",
    "lib/micron/reporter.rb",
    "lib/micron/reporter/console.rb",
    "lib/micron/reporter/coverage.rb",
    "lib/micron/runner.rb",
    "lib/micron/runner/backtrace_filter.rb",
    "lib/micron/runner/clazz.rb",
    "lib/micron/runner/debug.rb",
    "lib/micron/runner/exception_info.rb",
    "lib/micron/runner/fork_worker.rb",
    "lib/micron/runner/forking_clazz.rb",
    "lib/micron/runner/liveness_checker.rb",
    "lib/micron/runner/liveness_checker/ping.rb",
    "lib/micron/runner/liveness_checker/pong.rb",
    "lib/micron/runner/method.rb",
    "lib/micron/runner/parallel_clazz.rb",
    "lib/micron/runner/proc_clazz.rb",
    "lib/micron/runner/process_reaper.rb",
    "lib/micron/runner/shim.rb",
    "lib/micron/runner/test_file.rb",
    "lib/micron/test_case.rb",
    "lib/micron/test_case/assertions.rb",
    "lib/micron/test_case/lifecycle_hooks.rb",
    "lib/micron/test_case/teardown_coverage.rb",
    "lib/micron/util/ex.rb",
    "lib/micron/util/io.rb",
    "lib/micron/util/thread_dump.rb",
    "micron.gemspec"
  ]
  s.homepage = "http://github.com/chetan/micron"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.0"
  s.summary = "Minimal unit tests for Ruby"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<easycov>, [">= 0"])
      s.add_runtime_dependency(%q<hitimes>, [">= 0"])
      s.add_runtime_dependency(%q<colorize>, [">= 0"])
      s.add_development_dependency(%q<yard>, ["~> 0.8"])
      s.add_development_dependency(%q<bundler>, ["~> 1.1"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<minitest>, ["~> 4.0"])
    else
      s.add_dependency(%q<easycov>, [">= 0"])
      s.add_dependency(%q<hitimes>, [">= 0"])
      s.add_dependency(%q<colorize>, [">= 0"])
      s.add_dependency(%q<yard>, ["~> 0.8"])
      s.add_dependency(%q<bundler>, ["~> 1.1"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<minitest>, ["~> 4.0"])
    end
  else
    s.add_dependency(%q<easycov>, [">= 0"])
    s.add_dependency(%q<hitimes>, [">= 0"])
    s.add_dependency(%q<colorize>, [">= 0"])
    s.add_dependency(%q<yard>, ["~> 0.8"])
    s.add_dependency(%q<bundler>, ["~> 1.1"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<minitest>, ["~> 4.0"])
  end
end

