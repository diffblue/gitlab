# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class IncrementalWorker
      include ApplicationWorker

      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      idempotent!

      data_consistency :always
      feature_category :value_stream_management

      MAX_RUNTIME = 5.minutes

      delegate :monotonic_time, to: :'Gitlab::Metrics::System'

      def perform
        return if Feature.disabled?(:vsa_incremental_worker, default_enabled: :yaml)

        current_time = Time.current
        start_time = monotonic_time
        over_time = false

        loop do
          batch = Analytics::CycleAnalytics::Aggregation.load_batch(current_time)
          break if batch.empty?

          batch.each do |aggregation|
            Analytics::CycleAnalytics::AggregatorService.new(aggregation: aggregation).execute

            if monotonic_time - start_time >= MAX_RUNTIME
              over_time = true
              break
            end
          end

          break if over_time
        end
      end
    end
  end
end
