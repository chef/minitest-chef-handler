require File.expand_path('../../spec_helper', __FILE__)

describe MiniTest::Chef::Resources do

  let(:resources) { Class.new{ include MiniTest::Chef::Resources }.new }

  it "provides convenient access to current resource state" do
    [:cron, :directory, :file, :group, :ifconfig, :link, :mount, :package,
     :service, :user].each do |type|
      resources.must_respond_to(type)
    end
  end

  it "doesn't make available resources that are not idempotent" do
    [:bash, :erl_call, :execute, :ruby].each do |type|
      resources.wont_respond_to(type)
    end
  end

  it "doesn't make available file resources other than file itself" do
    [:cookbook_file, :remote_file, :template].each do |type|
      resources.wont_respond_to(type)
    end
  end

  describe "asserting with 'with' syntax" do
    let(:file) { ::Chef::Resource::File.new('/etc/foo') }
    it "can take an attribute name and value to assert against" do
      file.must_have(:name, '/etc/foo').must_equal file
    end
    it "allows assertions on resources to be chained together with 'with'" do
      file.must_have(:name, '/etc/foo').with(:action, 'create').must_equal(file)
    end
    it "allows assertions on resources to be chained together with 'and'" do
      file.must_have(:name, '/etc/foo').with(:action, 'create').
        and(:backup, 5).must_equal(file)
    end
    it "fails if the assertion is not met" do
      assert_triggered(/The file does not have the expected name/) do
        file.must_have(:name, '/etc/bar')
      end
      assert_triggered(/The file does not have the expected action/) do
        file.must_have(:name, '/etc/foo').with(:action, 'delete')
      end
      assert_triggered(/The file does not have the expected action/) do
        file.must_have(:name, '/etc/foo').and(:action, 'delete')
      end
    end
  end

end
