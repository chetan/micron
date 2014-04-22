
# for backwards compat with older micron
version = "4"
begin
  require "minitest"
  version = Minitest::VERSION[0]
rescue LoadError
end

if version == "4" then
  require "micron/compat/minitest47"
elsif version == "5"
  require "micron/compat/minitest5"
end
