# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class AggregationContext
      attr_accessor :cursor, :processed_records

      delegate :over_time?, to: :@runtime_limiter

      def initialize(cursor: {}, runtime_limiter: Analytics::CycleAnalytics::RuntimeLimiter.new)
        @processed_records = 0
        @cursor = cursor.compact
        @runtime_limiter = runtime_limiter
      end

      def processing_start!
        @start_time = Gitlab::Metrics::System.monotonic_time
      end

      def processing_finished!
        @end_time = Gitlab::Metrics::System.monotonic_time
      end

      def runtime
        @end_time - @start_time
      end
    end
  end
end
