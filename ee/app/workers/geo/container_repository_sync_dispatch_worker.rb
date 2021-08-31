# frozen_string_literal: true

module Geo
  class ContainerRepositorySyncDispatchWorker < Geo::Scheduler::Secondary::SchedulerWorker # rubocop:disable Scalability/IdempotentWorker
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    def perform
      unless ::Geo::ContainerRepositoryRegistry.replication_enabled?
        log_info('Container Registry replication is not enabled')
        return
      end

      super
    end

    private

    def max_capacity
      current_node.container_repositories_max_capacity
    end

    def schedule_job(repository_id)
      job_id = Geo::ContainerRepositorySyncWorker.perform_async(repository_id)

      { id: repository_id, job_id: job_id } if job_id
    end

    def scheduled_repository_ids
      scheduled_jobs.map { |data| data[:id] }
    end

    # Pools for new resources to be transferred
    #
    # @return [Array] resources to be transferred
    def load_pending_resources
      resources = find_jobs_never_attempted_sync(batch_size: db_retrieve_batch_size)
      remaining_capacity = db_retrieve_batch_size - resources.size

      if remaining_capacity == 0
        resources
      else
        resources + find_jobs_needs_sync_again(batch_size: remaining_capacity)
      end
    end

    def find_jobs_never_attempted_sync(batch_size:)
      registry_finder
        .find_registries_never_attempted_sync(batch_size: batch_size, except_ids: scheduled_repository_ids)
        .pluck_model_foreign_key
    end

    def find_jobs_needs_sync_again(batch_size:)
      registry_finder
        .find_registries_needs_sync_again(batch_size: batch_size, except_ids: scheduled_repository_ids)
        .pluck_model_foreign_key
    end

    def registry_finder
      @registry_finder ||= Geo::ContainerRepositoryRegistryFinder.new
    end
  end
end
