require 'minitest/unit'

module MiniTest
  module Chef
    class Handler < ::Chef::Handler
      def initialize(options = {})
        path = options.delete(:path) || './test/test_*.rb'
        Dir.glob(path).each {|test_suite| require test_suite}

        @options = options

        MiniTest::Unit.class_eval{ alias :_run :run } if RUBY_VERSION == "1.9.2"
      end

      def report
        # do not run tests if chef failed
        return if failed?

        runner = Runner.new(run_status)
        runner._run(miniunit_options)
      end

      private
      def miniunit_options
        options = []
        options << ['-n', @options[:filter]] if @options[:filter]
        options << "-v" if @options[:verbose]
        options << ['-s', @options[:seed]] if @options[:seed]
        options.flatten
      end
    end

    class Runner < MiniTest::Unit
      attr_reader :run_status

      def initialize(run_status)
        @run_status = run_status
        super()
      end
    end

    class TestCase < MiniTest::Unit::TestCase
      attr_reader :run_status, :node, :run_context

      def run(runner)
        if runner.respond_to?(:run_status)
          @run_status = runner.run_status
          @node = @run_status.node
          @run_context = @run_status.run_context
        end
        super(runner)
      end
    end
  end
end
