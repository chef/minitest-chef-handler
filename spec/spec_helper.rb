require 'minitest/autorun'
require 'minitest/spec'
require 'mocha/setup'

$LOAD_PATH << File.expand_path('../../lib', __FILE__)
require "minitest-chef-handler"

# Borrowed from MiniTest
def assert_triggered(expected)
  e = assert_raises(MiniTest::Assertion) do
    yield
  end
  msg = e.message.sub(/(---Backtrace---).*/m, '\1')
  msg.gsub!(/\(oid=[-0-9]+\)/, '(oid=N)')

  assert_match expected, msg
end
