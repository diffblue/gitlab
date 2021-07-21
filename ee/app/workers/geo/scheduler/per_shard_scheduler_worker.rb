# frozen_string_literal: true

module Geo
  module Scheduler
    class PerShardSchedulerWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext
      include ::Gitlab::Geo::LogHelpers
      include ::EachShardWorker

      feature_category :geo_replication
      tags :exclude_from_gitlab_com

      # These workers are enqueued every minute by sidekiq-cron. If one of them
      # is already enqueued or running, then there isn't a strong case for
      # enqueuing another. And there are edge cases where enqueuing another
      # would exacerbate a problem. See
      # https://gitlab.com/gitlab-org/gitlab/-/issues/328057.
      deduplicate :until_executed

      def perform
        each_eligible_shard { |shard_name| schedule_job(shard_name) }
      end

      def schedule_job(shard_name)
        raise NotImplementedError
      end
    end
  end
end
