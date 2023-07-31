# frozen_string_literal: true

module Analytics
  module ValueStreamDashboard
    class CountWorker
      include ApplicationWorker

      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      idempotent!

      data_consistency :sticky
      feature_category :value_stream_management

      CURSOR_KEY = 'value_stream_dashboard_count_cursor'
      CUTOFF_DAYS = 5

      def perform
        return unless should_perform?

        runtime_limiter = Analytics::CycleAnalytics::RuntimeLimiter.new

        cursor = load_cursor
        batch = Analytics::ValueStreamDashboard::Aggregation.load_batch(cursor)

        if batch.empty?
          persist_cursor(nil)
          return
        end

        batch.each do |aggregation|
          next unless feature_flag_enabled_for_aggregation?(aggregation)

          unless licensed?(aggregation)
            aggregation.update!(enabled: false)
            next
          end

          service_response = Analytics::ValueStreamDashboard::TopLevelGroupCounterService
            .new(aggregation: aggregation, cursor: cursor, runtime_limiter: runtime_limiter)
            .execute

          cursor = service_response[:cursor]

          break if service_response[:result] == :interrupted || runtime_limiter.over_time?
        end

        persist_cursor(cursor)
      end

      private

      def should_perform?
        Time.current.day >= (Time.current.end_of_month.day - CUTOFF_DAYS) &&
          License.feature_available?(:group_level_analytics_dashboard)
      end

      def load_cursor
        value = Gitlab::Redis::SharedState.with { |redis| redis.get(CURSOR_KEY) }
        return if value.nil?

        raw_cursor = Gitlab::Json.parse(value).symbolize_keys
        Analytics::ValueStreamDashboard::TopLevelGroupCounterService.load_cursor(raw_cursor: raw_cursor)
      end

      def persist_cursor(cursor)
        if cursor.nil?
          Gitlab::Redis::SharedState.with { |redis| redis.del(CURSOR_KEY) }
        else
          Gitlab::Redis::SharedState.with { |redis| redis.set(CURSOR_KEY, Gitlab::Json.dump(cursor.dump)) }
        end
      end

      def feature_flag_enabled_for_aggregation?(aggregation)
        Feature.enabled?(:value_stream_dashboard_on_off_setting, aggregation.namespace)
      end

      def licensed?(aggregation)
        aggregation.namespace.licensed_feature_available?(:group_level_analytics_dashboard)
      end
    end
  end
end
