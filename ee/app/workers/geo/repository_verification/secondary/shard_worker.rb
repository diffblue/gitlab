# frozen_string_literal: true

module Geo
  module RepositoryVerification
    module Secondary
      class ShardWorker < Geo::Scheduler::Secondary::SchedulerWorker # rubocop:disable Scalability/IdempotentWorker
        # rubocop:disable Scalability/CronWorkerContext
        # This worker does not perform work scoped to a context
        include CronjobQueue
        # rubocop:enable Scalability/CronWorkerContext

        attr_accessor :shard_name

        loggable_arguments 0

        def perform(shard_name)
          @shard_name = shard_name

          return unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)

          super()
        end

        def lease_key
          @lease_key ||= "#{self.class.name.underscore}:shard:#{shard_name}"
        end

        private

        def skip_cache_key
          "#{self.class.name.underscore}:shard:#{shard_name}:skip"
        end

        def worker_metadata
          { shard_name: shard_name }
        end

        def max_capacity
          Gitlab::Geo.verification_max_capacity_per_replicator_class
        end

        # rubocop:disable CodeReuse/ActiveRecord
        def load_pending_resources
          return [] unless valid_shard?

          project_ids =
            registry_finder
              .find_project_ids_pending_verification(batch_size: db_retrieve_batch_size, except_ids: scheduled_project_ids)

          Project
            .id_in(project_ids)
            .within_shards(shard_name)
            .pluck_primary_key
        end
        # rubocop:enable CodeReuse/ActiveRecord

        def scheduled_project_ids
          scheduled_jobs.map { |data| data[:project_id] }
        end

        # rubocop:disable CodeReuse/ActiveRecord
        def schedule_job(project_id)
          registry_id = Geo::ProjectRegistry.where(project_id: project_id).pick(:id)
          job_id = Geo::RepositoryVerification::Secondary::SingleWorker.with_status.perform_async(registry_id)

          { project_id: project_id, job_id: job_id } if job_id
        end
        # rubocop:enable CodeReuse/ActiveRecord

        def registry_finder
          @registry_finder ||= Geo::ProjectRegistryFinder.new
        end

        def valid_shard?
          return true unless current_node.selective_sync_by_shards?

          current_node.selective_sync_shards.include?(shard_name)
        end
      end
    end
  end
end
