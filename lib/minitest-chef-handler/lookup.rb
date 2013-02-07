module MiniTest
  module Chef
    module Lookup

      # Load the test suites.
      #
      # If the option "path" is specified we use it to load the tests from it.
      # The option can be a string or an array of paths.
      # Otherwise we load the tests according to the recipes seen.
      #
      def require_test_suites(options_path)
        paths = options_path || seen_recipes_paths
        Array(paths).each do |path|
          Dir.glob(path).each { |test_suite| require File.expand_path(test_suite) }
        end
      end

      # Collect test paths based in the recipes ran.
      #
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

          cookbook_paths = lookup_cookbook(base_path, cookbook_name)

          cookbook_paths.map do |path|
            file_test_pattern = "%s/tests/%s_test.rb" % [path, recipe_short_name]
            dir_test_pattern  = "%s/tests/%s/*_test.rb" % [path, recipe_short_name]
            file_spec_pattern = "%s/specs/%s_spec.rb" % [path, recipe_short_name]
            dir_spec_pattern  = "%s/specs/%s/*_spec.rb" % [path, recipe_short_name]

            [file_test_pattern, dir_test_pattern, file_spec_pattern, dir_spec_pattern]
          end.flatten
        end.flatten
      end

      # Internal - look for the right path to the cookbook given one or
      # several base paths.
      #
      # Path: String or Array representing the recipes base paths.
      # Name: Name of the cookbook
      #
      # Returns paths founded for the speficied cookbook.
      def lookup_cookbook(path, name)
        path_expr = Array(path).join(',')

        Dir.glob("{%s}/%s" % [path_expr, name])
      end
    end
  end
end
