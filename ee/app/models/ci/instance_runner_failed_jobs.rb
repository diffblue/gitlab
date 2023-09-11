# frozen_string_literal: true

module Ci
  class InstanceRunnerFailedJobs
    # Safety margin for situations where there is a mismatch between the async insert order and the finished_at value
    JOB_LIMIT_MARGIN = 10
    JOB_LIMIT = 100
    SUPPORTED_FAILURE_REASONS = %i[runner_system_failure].freeze

    class << self
      def track(build)
        return unless track_job?(build)

        with_redis do |redis|
          redis.pipelined do |pipeline|
            pipeline.lpush(key, build.id)
            pipeline.ltrim(key, 0, max_admissible_job_count - 1)
          end
        end
      end

      def recent_jobs(failure_reason:)
        unless SUPPORTED_FAILURE_REASONS.include?(failure_reason.to_sym)
          raise ArgumentError, "The only failure reason(s) supported are #{SUPPORTED_FAILURE_REASONS.join(', ')}"
        end

        return Ci::Build.none unless License.feature_available?(:runner_performance_insights)

        job_ids = with_redis do |redis|
          # Fetch a few more jobs in case there is a mismatch between the async insert order and
          # the finished_at value
          redis.lrange(key, 0, max_admissible_job_count - 1)
        end

        Ci::Build.id_in(job_ids)
          .where(failure_reason: failure_reason)
          .reorder(finished_at: :desc, id: :desc)
          .limit(JOB_LIMIT)
      end

      private

      def key
        self.class.name
      end

      def with_redis(&block)
        Gitlab::Redis::SharedState.with(&block)
      end

      def max_admissible_job_count
        JOB_LIMIT + JOB_LIMIT_MARGIN
      end

      def track_job?(build)
        License.feature_available?(:runner_performance_insights) &&
          SUPPORTED_FAILURE_REASONS.include?(build.failure_reason.to_sym) &&
          build.runner.instance_type?
      end
    end
  end
end
