# frozen_string_literal: true

module ComplianceManagement
  module MergeRequests
    class ComplianceViolationsConsistencyWorker
      include ApplicationWorker
      # This worker does not perform work scoped to a context
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      idempotent!
      data_consistency :always
      feature_category :compliance_management
      urgency :low

      # This cron worker is executed at an interval of 24 hours.
      # Maximum run time is kept as 4 minutes to avoid breaching maximum allowed execution latency of 5 minutes.
      MAX_RUN_TIME = 4.minutes
      LAST_PROCESSED_MR_VIOLATION_REDIS_KEY = 'last_processed_mr_violation_id'

      TimeoutError = Class.new(StandardError)

      def perform
        start_time

        compliance_violation_id = last_processed_violation_id

        # rubocop: disable CodeReuse/ActiveRecord
        ::MergeRequests::ComplianceViolation.where('id >= ?', compliance_violation_id).each_batch(of: 100) do |batch|
          batch.preload(:merge_request).each do |violation|
            if over_time?
              save_last_processed_violation_id(violation.id)
              raise TimeoutError
            end

            ComplianceManagement::MergeRequests::ComplianceViolationsConsistencyService.new(violation).execute
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord]
        reset_last_processed_violation_id
      rescue TimeoutError
        # in case of TimeoutError, recursively call the worker again so that the rest of the rows are processed.
        ::ComplianceManagement::MergeRequests::ComplianceViolationsConsistencyWorker.perform_async
      end

      private

      def start_time
        @start_time ||= ::Gitlab::Metrics::System.monotonic_time
      end

      def over_time?
        (::Gitlab::Metrics::System.monotonic_time - start_time) > MAX_RUN_TIME
      end

      def save_last_processed_violation_id(compliance_violation_id)
        with_redis do |redis|
          redis.set(LAST_PROCESSED_MR_VIOLATION_REDIS_KEY, compliance_violation_id)
        end
      end

      def last_processed_violation_id
        with_redis do |redis|
          redis.get(LAST_PROCESSED_MR_VIOLATION_REDIS_KEY).to_i
        end
      end

      def reset_last_processed_violation_id
        with_redis do |redis|
          redis.del(LAST_PROCESSED_MR_VIOLATION_REDIS_KEY)
        end
      end

      def with_redis(&block)
        Gitlab::Redis::Cache.with(&block) # rubocop:disable CodeReuse/ActiveRecord
      end
    end
  end
end
