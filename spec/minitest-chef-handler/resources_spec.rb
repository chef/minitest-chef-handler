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
      assert_triggered("The file /etc/foo does not have the expected name") do
        file.must_have(:name, '/etc/bar')
      end
      assert_triggered("The file /etc/foo does not have the expected action") do
        file.must_have(:name, '/etc/foo').with(:action, 'delete')
      end
      assert_triggered("The file /etc/foo does not have the expected action") do
        file.must_have(:name, '/etc/foo').and(:action, 'delete')
      end
    end
  end

  describe "asserting with :mode" do
    let(:file) { ::Chef::Resource::File.new('/etc/foo') }

    it "fail when the mode is nil" do
      file.set_or_return(:mode, nil, {})

      assert_triggered(/Expected: "755"\n  Actual: nil/) do
        file.must_have(:mode, '755')
      end
    end

    [["integer", 0755], ["string", "0755"]].each do |type, mode|
      it "fails with incorrect modes on #{type} mode" do
        file.define_singleton_method(:mode){ mode }
        def file.mode; 0755; end
        assert_triggered(/Expected: "644"\n  Actual: "755"/) do
          file.must_have(:mode, 0644)
        end
        assert_triggered(/Expected: "644"\n  Actual: "755"/) do
          file.must_have(:mode, 0644)
        end
      end

      it "passes with correct modes on #{type} mode" do
        file.define_singleton_method(:mode){ mode }
        file.must_have(:mode, '00755')
        file.must_have(:mode, '00755')
        file.must_have(:mode, '0755')
        file.must_have(:mode, '755')
        file.must_have(:mode, 0755)
      end
    end
  end

  describe "asserting with :owner" do
    let(:file) { ::Chef::Resource::File.new('/etc/foo') }

    it "fail when the owner is nil" do
      file.set_or_return(:owner, nil, {})

      assert_triggered(/Expected: "david"\n  Actual: nil/) do
        file.must_have(:owner, 'david')
      end
    end
  end

  describe "asserting with :group" do
    let(:file) { ::Chef::Resource::File.new('/etc/foo') }

    it "fail when the group is nil" do
      file.set_or_return(:group, nil, {})

      assert_triggered(/Expected: "staff"\n  Actual: nil/) do
        file.must_have(:owner, 'staff')
      end
    end
  end
end
