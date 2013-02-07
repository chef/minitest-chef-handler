require File.expand_path('../../spec_helper', __FILE__)
require "chef/run_list/run_list_item"

describe MiniTest::Chef::Lookup do
  include MiniTest::Chef::Lookup

  describe "#require_test_suites" do
    it "expands paths correctly" do
      expects(:require).with("/tmp")

      Dir.chdir("/") do
        require_test_suites(["tmp"])
      end
    end

    it "requires multiple paths" do
      expects(:require).times(2)

      require_test_suites(["lib/*"])
    end
  end

  describe "#used_recipe_names" do
    before do
      stubs(:run_status => stub(:node => stub(:run_state => {})))
    end

    it "uses seen_recipes if run_state is not empty" do
      run_status.node.run_state[:seen_recipes] = {"some" => 1, "other" => 2}
      used_recipe_names.must_equal ["some", "other"]
    end

    it "uses run_list if run_state is empty" do
      run_status.node.stubs(:run_list => %w(recipe[foo] recipe[bar] role[someone]).map { |i| Chef::RunList::RunListItem.new(i) })
      used_recipe_names.must_equal ["foo", "bar"]
    end
  end
end
