require 'minitest/spec'
#
# Cookbook Name:: spec_examples
# Spec:: default
#
# Copyright 2012, Opscode, Inc.
#
describe_recipe 'spec_examples::default' do
  describe "files" do
    # = Testing that a file exists =
    #
    # The simplest assertion is that a file exists following the Chef run:
    it "creates the config file" do
      file("/etc/fstab").must_exist
    end

    # All of the matchers starting with 'must_' also have a negative 'wont_'.
    # So conversely we can also check that a file does not exist:
    it "ensures that the foobar file is removed if present" do
      file("/etc/foobar").wont_exist
    end

    # = Testing for behaviour =
    #
    # Chef has multiple resource types that create files. We use file to test
    # all of them.
    #
    # This is not valid:
    #
    #     cookbook_file(file_path).must_exist
    #
    # Testing the behaviour - is the file is created with the right content?
    # - is preferable to testing how the file gets there. This way if your
    # recipe switches from using a cookbook_file resource to a template resource
    # your tests should still work.

    # Let's go beyond just checking for existence to testing the other file
    # attributes.

    # = Other file attributes =

    # Use .with on a resource and specify the attribute and expected value:
    it "has the expected ownership and permissions" do
      file("/etc/fstab").must_exist.with(:owner, "root")
    end

    # You can also use .must_have:
    it "only root can modify the config file" do
      file("/etc/fstab").must_have(:mode, "644")
    end

    # And you can chain attributes together if you are asserting several.
    # You don't want to get too carried away doing this but it can be useful.
    it "only root can modify the config file" do
      file("/etc/fstab").must_have(:mode, "644").with(:owner, "root").and(:group, "root")
      assert_file "/etc/fstab", "root", "root", 0644
    end

    # Alternatively you could express it like this so each assertion is nicely
    # self-contained:
    describe "only root can modify the config file - alternate syntax" do
      let(:config) { file("/etc/fstab") }
      it { config.must_have(:mode, "644") }
      it { config.must_have(:owner, "root") }
      it { config.must_have(:group, "root") }
    end

    # = Checking file content =

    # You can check if a config file contains a string:
    it "sets phasers to stun" do
      file('/tmp/foo').must_include 'phaser_setting=stun'
    end

    # Or if a file matches a regular expression:
    it "sets phasers to off or stun" do
      file('/tmp/foo').must_match /^phaser_setting=(off|stun)$/
      file('/tmp/foo').wont_match /^phaser_setting=kill$/
    end

    # = Checking file timestamps =
    it "touches the config to force a reload" do
      file("/tmp/foo").must_be_modified_after(run_status.start_time)
    end

    it "leaves the hosts file alone" do
      file("/etc/hosts").wont_be_modified_after(run_status.start_time)
    end

    # = Directories =

    # The file existence and permissions matchers are also valid for
    # directories:
    it "creates directories" do
      directory("/etc/").must_exist.with(:owner, "root")
      assert_directory "/etc", "root", "root", 0755
    end

    # = Links =

    it "symlinks the foo in" do
      link("/tmp/foo-symbolic").must_exist.with(
        :link_type, :symbolic).and(:to, "/tmp/foo")
      assert_symlinked_file "/tmp/foo-symbolic", "root", "root", 0644
    end
  end

  describe "packages" do
    # = Checking for package install =
    it "installs my favorite pager" do
      package("less").must_be_installed
    end

    it "doesn't install emacs" do
      package("emacs").wont_be_installed
    end

    # = Package names =
    #
    # When writing cookbooks intended for use on multiple different operating
    # systems or flavors you will often need to supply a different package
    # name based on the node.platform.
    #
    # If you choose to test for package installation in your tests then you
    # will also need to provide the right package name, which can lead to
    # duplication.

    it "installs my favorite pager" do
      package(node['spec_examples']['pager']).must_be_installed
    end

    # = Package versions =
    it "installs the package with the right version" do
      package("less").must_be_installed.with(:version, "444-1ubuntu1")
    end
  end

  describe "services" do
    # You can assert that a service must be running following the converge:
    it "runs as a daemon" do
      service("ssh").must_be_running
    end

    # And that it will start when the server boots:
    # Pending FIXME: Chef::Provider::Service::Upstart is not supported by default
    it "boots on startup" #do
    #  service("ssh").must_be_enabled
    #end
  end

  describe "users and groups" do
    # = Users =

    # Check if a user has been created:
    it "creates a user for the daemon to run as" do
      user("sshd").must_exist
    end

    # You can also use .with here to test attributes:
    it "creates the user with the expected properties" do
      user("sshd").must_exist.with(:home, '/var/run/sshd')
    end

    it "has an informative comment against the user" do
      user("list").must_have(:comment, 'Mailing List Manager')
    end

    it "has the expected uid" do
      user("root").must_have(:uid, 0)
    end

    it "has the expected gid" do
      user("root").must_have(:gid, 0)
    end

    # = Groups =

    it "creates the users group" do
      group("chipmunks").must_exist
    end

    # Check for group membership, you can pass a single user or an array of
    # users:
    it "grants group membership to the expected users" do
      group("chipmunks").must_include('alvin')
      group("chipmunks").must_include(['alvin', 'simon'])
      group("chipmunks").wont_include('michelangelo')
    end

    # Alternatively rather than checking if the group includes specific users
    # you can test that the group is made up of exactly the users you specify:
    it "grants group membership only to specific users" do
      group("chipmunks").must_have(:members, ['alvin', 'simon', 'theodore'])
    end
  end

  describe "cron entries" do
    it "creates a crontab entry" do
      cron("noop").must_exist.with(:hour, "5").and(:minute, "0").and(:day, "*")
    end

    it "removes the self-destruct countdown" do
      cron("self-destruct").wont_exist
    end
  end

  # Note that the syntax for testing the mount resource is slightly different.
  # You need to specify the device in the call to mount.
  describe "mount" do
    it { mount("/mnt", :device => "/dev/null").must_be_mounted }
    it { mount("/mnt", :device => "/dev/null").must_be_enabled.with(:fstype, "tmpfs") }
    it { mount("/mnt", :device => "/dev/olympus").wont_be_mounted }
  end

  describe "networking" do
    # = Test network interface settings =
    describe "ifconfig" do
      it "has the expected network interfaces configured" do
        ifconfig(node['ipaddress'], :device => "eth0").must_exist
        ifconfig(node['ipaddress'], :device => "eth1").wont_exist
      end
    end
  end

  describe "misc" do
    it "can run assert_sh" do
      result = assert_sh("ls /vagrant")
      assert_includes result, "Gemfile"
    end
  end
end
