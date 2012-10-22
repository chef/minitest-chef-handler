require File.expand_path('../../spec_helper', __FILE__)

describe MiniTest::Chef::Spec do

  let(:spec) { Class.new(MiniTest::Chef::Spec).new(:sample_spec) }

  it "makes the node object available" do
    spec.must_respond_to(:node)
  end

  it "makes minitest-chef-handler assertions available" do
    spec.must_respond_to(:assert_installed)
  end

  it "makes minitest-chef-handler resource helpers available" do
    spec.must_respond_to(:package)
  end
end
