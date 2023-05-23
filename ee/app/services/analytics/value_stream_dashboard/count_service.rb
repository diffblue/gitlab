# frozen_string_literal: true

module Analytics
  module ValueStreamDashboard
    class CountService
      def initialize(aggregation:, cursor:)
        @aggregation = aggregation
        @cursor = cursor
      end

      def execute
        # count logic comes here
        ServiceResponse.success(payload: { cursor: cursor })
      end

      private

      attr_reader :aggregation, :cursor
    end
  end
end
