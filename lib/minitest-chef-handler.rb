require 'minitest-chef-handler/context'
require 'minitest-chef-handler/resources'
require 'minitest-chef-handler/unit'
require 'minitest-chef-handler/spec'
require 'minitest-chef-handler/runner'
require 'minitest-chef-handler/ci_runner'

require 'minitest-chef-handler/assertions'
require 'minitest-chef-handler/infections'

require 'minitest-chef-handler/lookup'

module MiniTest
  module Chef
    class Handler < ::Chef::Handler
      include Lookup

      def initialize(options = {})
        @options = options
      end

      def report
        # do not run tests if chef failed
        return if failed?

        require_test_suites(@options.delete(:path))

        if @options[:ci_reports]
          ENV['CI_REPORTS'] = @options[:ci_reports]
          runner = CIRunner.new(run_status)
        else
          runner = Runner.new(run_status)
        end

        if custom_runner?
          runner._run(miniunit_options)
        else
          runner.run(miniunit_options)
        end

        if runner.failures.nonzero? || runner.errors.nonzero?
          ::Chef::Client.when_run_completes_successfully do |run_status|
            raise "MiniTest failed with #{runner.failures} failure(s) and #{runner.errors} error(s)."
          end
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
  end
end
