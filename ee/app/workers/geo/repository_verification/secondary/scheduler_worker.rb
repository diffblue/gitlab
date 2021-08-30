# frozen_string_literal: true

module Geo
  module RepositoryVerification
    module Secondary
      class SchedulerWorker < Geo::Scheduler::Secondary::PerShardSchedulerWorker # rubocop:disable Scalability/IdempotentWorker
        def perform
          return unless Gitlab::Geo.repository_verification_enabled?

          super
        end

        def schedule_job(shard_name)
          Geo::RepositoryVerification::Secondary::ShardWorker.perform_async(shard_name)
        end
      end
    end
  end
end
