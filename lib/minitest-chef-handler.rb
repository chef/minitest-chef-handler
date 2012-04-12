require 'etc'
require 'minitest/unit'
require 'minitest/spec'

# Allow the exit code to be set to fail the build, while still ensuring that all
# notifications are handled before exiting. This is preferable to raising or
# exiting from our handler and breaking other handlers.
Chef::Client.class_eval do
  class << self
    attr_accessor :exit_error
  end

  alias :old_run_completed_successfully :run_completed_successfully

  def run_completed_successfully
    old_run_completed_successfully
    exit_error = Chef::Client.exit_error
    Chef::Application.fatal!(exit_error[:message], exit_error[:code]) if exit_error
  end
end

module MiniTest
  module Chef
    class Handler < ::Chef::Handler
      def initialize(options = {})
        path = options.delete(:path) || './test/test_*.rb'
        Dir.glob(path).each {|test_suite| require test_suite}

        @options = options
      end

      def report
        # do not run tests if chef failed
        return if failed?

        runner = Runner.new(run_status)
        test_failures = if custom_runner?
          runner._run(miniunit_options)
        else
          runner.run(miniunit_options)
        end
        ensure_build_fails if test_failures and test_failures > 0
      end

      private

      def ensure_build_fails
        if ::Chef::Config[:solo]
          ::Chef::Client.exit_error =
            {:message => 'There were test failures', :code => 3}
        end
      end

      def miniunit_options
        options = []
        options << ['-n', @options[:filter]] if @options[:filter]
        options << "-v" if @options[:verbose]
        options << ['-s', @options[:seed]] if @options[:seed]
        options.flatten
      end

      # Before Minitest 2.1.0 Minitest::Unit called `run` because the custom runners support was poorly designed.
      # See: https://github.com/seattlerb/minitest/commit/6023c879cf3d5169953ee929343b679de4a48bbc
      #
      # Using this workaround we still allow to use any other runner with the test suite for versions greater than 2.1.0.
      # If the test suite doesn't use any chef injection capability it still can be ran with the default Minitest runner.
      def custom_runner?
        Gem::Version.new(MiniTest::Unit::VERSION) >= Gem::Version.new('2.1.0')
      end
    end

    class Runner < MiniTest::Unit
      attr_reader :run_status

      def initialize(run_status)
        @run_status = run_status
        super()
      end
    end

    module RunState
      attr_reader :run_status, :node, :run_context

      def run_start
        @run_status.start_time
      end

      def ran_recipe?(recipe)
        node.run_state[:seen_recipes].keys.include?(recipe)
      end

      def current_recipe
        self.class.name.split('::')[0..1].join('::')
      end

      def run(runner)
        if runner.respond_to?(:run_status)
          @run_status = runner.run_status
          @node = @run_status.node
          @run_context = @run_status.run_context

          # Don't run this test if the recipe was not part of the Chef run.
          # TODO: It should be possible to avoid being called at all by passing
          # a block to MiniTest::Spec.register_spec_type.
          return unless ran_recipe?(current_recipe)
        end
        super(runner)
      end
    end

    module Resources
      include ::Chef::Mixin::ConvertToClassName

      # Expose Chef support for loading current resource state
      def self.register_resource(resource, *required_args)
        define_method(resource) do |name, *options|
          clazz = ::Chef::Resource.const_get(convert_to_class_name(resource.to_s))
          res = clazz.new(name, run_context)
          required_args.each do |arg|
            res.send(arg, options.first[arg])
          end
          provider = ::Chef::Platform.provider_for_resource(res)
          provider.load_current_resource
          provider.current_resource
        end
      end

      # These resources can be instantiated by name attribute only
      #   file('/etc/foo.conf')
      [:cron, :directory, :file, :group,
       :link, :package, :service, :user].each{ |r| register_resource(r) }

      # These resources need additional arguments
      #   mount('/mnt', :device => '/dev/sdb1')
      register_resource(:ifconfig, :device)
      register_resource(:mount, :device)

      ::Chef::Resource.class_eval do
        include MiniTest::Assertions

        def with(attribute, values)
          assert_equal values, resource_value(attribute, values)
          self
        end
        alias :and :with
        alias :must_have :with

        private

        def resource_value(attribute, values)
          case attribute
            when :mode then mode.kind_of?(Integer) ? mode.to_s(8) : mode.to_s
            when :owner || :user then Etc.getpwuid(owner).name
            when :group then Etc.getgrgid(group).name
          else
            send(attribute)
          end
        end

      end
    end

    class TestCase < MiniTest::Unit::TestCase
      include MiniTest::Chef::Resources
      include MiniTest::Chef::RunState
    end

    class MiniTest::Chef::Spec < MiniTest::Spec
      include MiniTest::Chef::Resources
      include MiniTest::Chef::RunState
    end

    # MiniTest::Chef expectations will be available to specs that look like Chef recipes.
    #   describe "apache2::default" do
    MiniTest::Spec.register_spec_type(/^[a-z_\-]+\:\:[a-z_\-]+$/, MiniTest::Chef::Spec)
  end

  module Assertions
    class << self
      include ::Chef::Mixin::ConvertToClassName
    end

    def self.resource_exists(name, options)
      options[:description] = name unless options.key?(:description)
      define_method("assert_#{name}_exists") do |resource|
        refute resource.send(options[:field]).nil?,
          "Expected #{options[:description]} '#{resource.name}' to exist"
        resource
      end
      define_method("refute_#{name}_exists") do |resource|
        assert resource.send(options[:field]).nil?,
          "Expected #{options[:description]} '#{resource.name}' to not exist"
        resource
      end
    end

    resource_exists :cron,     :field => :command, :description => 'cron entry'
    resource_exists :group,    :field => :gid
    resource_exists :ifconfig, :field => :device, :description => 'network interface'
    resource_exists :link,     :field => :to
    resource_exists :user,     :field => :uid

    def assert_enabled(service)
      assert service.enabled, "Expected service '#{service.name}' to be enabled"
      service
    end

    def refute_enabled(service)
      refute service.enabled, "Expected service '#{service.name}' to be disabled"
      service
    end

    def assert_group_includes(members, group)
      members = [members] unless members.respond_to?(:&)
      assert group.members & members == members, "Expected group '#{group.name}' to include members: #{members.join(', ')}"
      group
    end

    def refute_group_includes(members, group)
      members = [members] unless members.respond_to?(:&)
      refute group.members & members == members, "Expected group '#{group.name}' not to include members: #{members.join(', ')}"
      group
    end

    def assert_includes_content(file, content)
      assert File.read(file.path).include?(content)
    end

    def refute_includes_content(file, content)
      refute File.read(file.path).include?(content)
    end

    def assert_installed(package)
      refute package.version.nil?, "Expected package '#{package.name}' to be installed"
      package
    end

    def refute_installed(package)
      assert package.version.nil?, "Expected package '#{package.name}' to not be installed"
      package
    end

    def assert_matches_content(file, regexp)
      assert File.read(file.path).match(regexp)
      file
    end

    def refute_matches_content(file, regexp)
      refute File.read(file.path).match(regexp)
      file
    end

    def assert_modified_after(file_or_dir, time)
      assert File.mtime(file_or_dir.path).to_i >= time.to_i
      file_or_dir
    end

    def refute_modified_after(file_or_dir, time)
      refute File.mtime(file_or_dir.path) >= time
      file_or_dir
    end

    def assert_mounted(mount)
      assert mount.mounted, "Expected mount '#{mount.name}' to be mounted"
      mount
    end

    def refute_mounted(mount)
      refute mount.mounted, "Expected mount' #{mount.name}' to not be mounted"
      mount
    end

    def assert_mount_enabled(mount)
      assert mount.enabled, "Expected mount '#{mount.name}' to be enabled"
      mount
    end

    def refute_mount_enabled(mount)
      refute mount.enabled, "Expected mount' #{mount.name}' to not be enabled"
      mount
    end

    def assert_path_exists(file_or_dir)
      assert File.exists?(file_or_dir.path)
      file_or_dir
    end

    def refute_path_exists(file_or_dir)
      refute File.exists?(file_or_dir.path)
      file_or_dir
    end

    def assert_running(service)
      assert service.running, "Expected service '#{service.name}' to be running"
      service
    end

    def refute_running(service)
      refute service.running, "Expected service '#{service.name}' to not be running"
      service
    end

    # MiniTest::Spec

    def self.infect_resource(resource, meth, new_name)
      clazz = ::Chef::Resource.const_get(convert_to_class_name(resource.to_s))
      clazz.infect_an_assertion "assert_#{meth}".to_sym,
        "must_#{new_name}".to_sym, :only_one_argument
      clazz.infect_an_assertion "refute_#{meth}".to_sym,
        "wont_#{new_name}".to_sym, :only_one_argument
    end

    infect_resource :cron, :cron_exists, :exist
    infect_resource :directory, :modified_after, :be_modified_after
    infect_resource :directory, :path_exists, :exist
    infect_resource :file, :includes_content, :include
    infect_resource :file, :matches_content, :match
    infect_resource :file, :modified_after, :be_modified_after
    infect_resource :file, :path_exists, :exist
    infect_resource :group, :group_exists, :exist
    infect_resource :ifconfig, :ifconfig_exists, :exist
    infect_resource :link, :link_exists, :exist
    infect_resource :mount, :mounted, :be_mounted
    infect_resource :mount, :mount_enabled, :be_enabled
    infect_resource :service, :enabled, :be_enabled
    infect_resource :service, :running, :be_running
    infect_resource :package, :installed, :be_installed
    infect_resource :user, :user_exists, :exist

    ::Chef::Resource::Group.infect_an_assertion :assert_group_includes, :must_include
    ::Chef::Resource::Group.infect_an_assertion :refute_group_includes, :wont_include
  end

end
