require File.expand_path('../../spec_helper', __FILE__)

describe MiniTest::Chef::Infections do

  include MiniTest::Chef::Infections

  def has_matchers(const, matchers)
    matchers.each { |m| const.public_instance_methods.must_include(m) }
  end

  it "needs to infect the expected Chef resources" do
    has_matchers ::Chef::Resource::Cron, [:must_exist, :wont_exist]
    has_matchers ::Chef::Resource::Directory, [:must_be_modified_after,
      :wont_be_modified_after, :must_exist, :wont_exist]
    has_matchers ::Chef::Resource::File, [:must_be_modified_after,
      :wont_be_modified_after, :must_exist, :wont_exist, :must_include,
      :wont_include, :must_match, :wont_match]
    has_matchers ::Chef::Resource::Group, [:must_exist, :wont_exist,
      :must_include, :wont_include]
    has_matchers ::Chef::Resource::Ifconfig, [:must_exist, :wont_exist]
    has_matchers ::Chef::Resource::Link, [:must_exist, :wont_exist]
    has_matchers ::Chef::Resource::Mount, [:must_be_enabled, :wont_be_enabled,
      :must_be_mounted, :wont_be_mounted]
    has_matchers ::Chef::Resource::Package, [:must_be_installed,
      :wont_be_installed]
    has_matchers ::Chef::Resource::Service, [:must_be_enabled, :wont_be_enabled,
      :must_be_running, :wont_be_running]
    has_matchers ::Chef::Resource::User, [:must_exist, :wont_exist]
  end

end
