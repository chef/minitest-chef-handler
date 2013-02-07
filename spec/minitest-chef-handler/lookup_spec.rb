require File.expand_path('../../spec_helper', __FILE__)

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
end
