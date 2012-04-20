module MiniTest
  module Chef
    require 'minitest/unit'

    class TestCase < MiniTest::Unit::TestCase
      include Assertions
      include Context
      include Resources
    end
  end
end
