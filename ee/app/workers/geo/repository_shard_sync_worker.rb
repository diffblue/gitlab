# frozen_string_literal: true

module Geo
  class RepositoryShardSyncWorker < Geo::Scheduler::Secondary::SchedulerWorker # rubocop:disable Scalability/IdempotentWorker
    sidekiq_options retry: false
    loggable_arguments 0

    attr_accessor :shard_name

    def perform(shard_name)
      @shard_name = shard_name

      unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)
        log_error("Skipped scheduling syncs due to unhealthy shard", nil, { shard_name: shard_name })
        return
      end

      super()
    end

    private

    def skip_cache_key
      "#{self.class.name.underscore}:shard:#{shard_name}:skip"
    end

    def worker_metadata
      { shard_name: shard_name }
    end

    # We need a custom key here since we are running one worker per shard
    def lease_key
      @lease_key ||= "#{self.class.name.underscore}:shard:#{shard_name}"
    end

    def max_capacity
      healthy_count = Gitlab::ShardHealthCache.healthy_shard_count

      # If we don't have a count, that means that for some reason
      # RepositorySyncWorker stopped running/updating the cache. We might
      # be trying to shut down Geo while this job may still be running.
      return 0 unless healthy_count.to_i > 0

      capacity_per_shard = current_node.repos_max_capacity / healthy_count

      [1, capacity_per_shard.to_i].max
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def schedule_job(project_id)
      registry = Geo::ProjectRegistry.find_or_initialize_by(project_id: project_id)

      job_id = Geo::ProjectSyncWorker.with_status.perform_async(
        project_id,
        sync_repository: registry.repository_sync_due?(Time.current),
        sync_wiki: registry.wiki_sync_due?(Time.current)
      )

      { project_id: project_id, job_id: job_id } if job_id
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def scheduled_project_ids
      scheduled_jobs.map { |data| data[:project_id] }
    end

    def load_pending_resources
      return [] unless valid_shard?

      resources = find_jobs_never_attempted_sync(except_ids: scheduled_project_ids, batch_size: db_retrieve_batch_size)
      remaining_capacity = db_retrieve_batch_size - resources.size

      if remaining_capacity == 0
        resources
      else
        resources + find_jobs_needs_sync_again(except_ids: scheduled_project_ids + resources, batch_size: remaining_capacity)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_jobs_never_attempted_sync(except_ids:, batch_size:)
      project_ids =
        registry_finder
          .find_registries_never_attempted_sync(batch_size: batch_size, except_ids: except_ids)
          .pluck_model_foreign_key

      find_project_ids_within_shard(project_ids, direction: :desc)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_jobs_needs_sync_again(except_ids:, batch_size:)
      project_ids =
        registry_finder
          .find_registries_needs_sync_again(batch_size: batch_size, except_ids: except_ids)
          .pluck_model_foreign_key

      find_project_ids_within_shard(project_ids, direction: :asc)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def valid_shard?
      return true unless current_node.selective_sync_by_shards?

      current_node.selective_sync_shards.include?(shard_name)
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def find_project_ids_within_shard(project_ids, direction:)
      Project
        .id_in(project_ids)
        .within_shards(shard_name)
        .reorder(last_repository_updated_at: direction)
        .pluck_primary_key
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def registry_finder
      @registry_finder ||= Geo::ProjectRegistryFinder.new
    end
  end
end
