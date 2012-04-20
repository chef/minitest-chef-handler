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
        path = options.delete(:path) || './test/test_*.rb'
        Dir.glob(path).each {|test_suite| require test_suite}

        @options = options
      end

      def report
        # do not run tests if chef failed
        return if failed?

        runner = Runner.new(run_status)

        if custom_runner?
          runner._run(miniunit_options)
        else
          runner.run(miniunit_options)
        end
      end

      private

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
