module MiniTest
  module Chef
    require 'minitest/spec'

    class Spec < MiniTest::Spec
      include Assertions
      include Context
      include Resources
    end

    MiniTest::Spec.register_spec_type(/\Arecipe::/, MiniTest::Chef::Spec)
  end
end

module Kernel
  def describe_recipe(desc, additional_desc = nil, &block)
    describe('recipe::' + desc, additional_desc, &block)
  end
end
