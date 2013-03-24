require 'ci/reporter/minitest'

module MiniTest
  module Chef
    class CIRunner < CI::Reporter::Runner
      attr_reader :run_status

      def initialize(run_status)
        @run_status = run_status
        super()
      end
    end
  end
end
