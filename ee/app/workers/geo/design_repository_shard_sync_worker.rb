# frozen_string_literal: true

module Geo
  class DesignRepositoryShardSyncWorker < RepositoryShardSyncWorker # rubocop:disable Scalability/IdempotentWorker
    private

    def schedule_job(project_id)
      job_id = Geo::DesignRepositorySyncWorker.with_status.perform_async(project_id)

      { project_id: project_id, job_id: job_id } if job_id
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

    def registry_finder
      @registry_finder ||= Geo::DesignRegistryFinder.new
    end
  end
end
