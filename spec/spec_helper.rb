require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/spec'

require File.expand_path('../../lib/minitest-chef-handler', __FILE__)

# Borrowed from MiniTest
def assert_triggered(expected)
  e = assert_raises(MiniTest::Assertion) do
    yield
  end
  msg = e.message.sub(/(---Backtrace---).*/m, '\1')
  msg.gsub!(/\(oid=[-0-9]+\)/, '(oid=N)')

  assert_match expected, msg
end
