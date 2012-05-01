require 'minitest-chef-handler/context'
require 'minitest-chef-handler/resources'
require 'minitest-chef-handler/unit'
require 'minitest-chef-handler/spec'
require 'minitest-chef-handler/runner'

require 'minitest-chef-handler/assertions'
require 'minitest-chef-handler/infections'

module MiniTest
  module Chef
    class Handler < ::Chef::Handler
      def initialize(options = {})
        @options = options
      end

      def report
        # do not run tests if chef failed
        return if failed?

        require_test_suites
        runner = Runner.new(run_status)

        if custom_runner?
          runner._run(miniunit_options)
        else
          runner.run(miniunit_options)
        end
      end

      private

      #
      # Load the test suites.
      # If the option "path" is specified we use it to load the tests from it.
      # The option can be a string or an array of paths.
      # Otherwise we load the tests according to the recipes seen.
      #
      def require_test_suites
        paths = @options.delete(:path) || seen_recipes_paths
        Array(paths).each do |path|
          Dir.glob(path).each {|test_suite| require test_suite}
        end
      end

      #
      # Collect test paths based in the recipes ran.
      # It loads the tests based in the name of the cookbook and the name of the recipe.
      # The tests must be under the cookbooks directory.
      #
      # Examples:
      #
      # If the seen recipes includes the recipe "foo" we try to load tests from:
      #
      #   cookbooks/foo/tests/default_test.rb
      #   cookbooks/foo/tests/default/*_test.rb
      #
      #   cookbooks/foo/specs/default_spec.rb
      #   cookbooks/foo/specs/default/*_spec.rb
      #
      # If the seen recipes includes the recipe "foo::install" we try to load tests from:
      #
      #   cookbooks/foo/tests/install_test.rb
      #   cookbooks/foo/tests/install/*_test.rb
      #
      #   cookbooks/foo/specs/install_spec.rb
      #   cookbooks/foo/specs/install/*_spec.rb
      #
      def seen_recipes_paths
        run_status.node.run_state[:seen_recipes].keys.map do |recipe_name|
          cookbook_name, recipe_short_name = ::Chef::Recipe.parse_recipe_name(recipe_name)
          base_path = ::Chef::Config[:cookbook_path]

          file_test_pattern = "%s/%s/tests/%s_test.rb" % [base_path, cookbook_name, recipe_short_name]
          dir_test_pattern  = "%s/%s/tests/%s/*_test.rb" % [base_path, cookbook_name, recipe_short_name]
          file_spec_pattern = "%s/%s/specs/%s_spec.rb" % [base_path, cookbook_name, recipe_short_name]
          dir_spec_pattern  = "%s/%s/specs/%s/*_spec.rb" % [base_path, cookbook_name, recipe_short_name]

          [file_test_pattern, dir_test_pattern, file_spec_pattern, dir_spec_pattern]
        end.flatten
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
  end
end
