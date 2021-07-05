# frozen_string_literal: true

module Geo
  class RepositoriesCleanUpWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include ExclusiveLeaseGuard
    include GeoQueue
    include Gitlab::Geo::LogHelpers
    include Gitlab::ShellAdapter

    BATCH_SIZE = 250
    LEASE_TIMEOUT = 60.minutes

    # rubocop:disable CodeReuse/ActiveRecord
    def perform(geo_node_id)
      try_obtain_lease do
        node = GeoNode.find(geo_node_id)
        break unless node.selective_sync?

        Geo::ProjectRegistry.select(:id, :project_id).find_in_batches(batch_size: BATCH_SIZE) do |registries|
          tracked_project_ids = registries.map(&:project_id)
          replicable_project_ids = node.projects.id_in(tracked_project_ids).pluck_primary_key
          unused_tracked_project_ids = tracked_project_ids - replicable_project_ids
          clean_up_repositories(unused_tracked_project_ids)
        end
      end
    rescue ActiveRecord::RecordNotFound => error
      log_error('Could not find Geo node, skipping repositories clean up', error, geo_node_id: geo_node_id)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    def clean_up_repositories(unused_tracked_project_ids)
      unused_projects = Project.id_in(unused_tracked_project_ids)

      unused_projects.each do |project|
        clean_up_repository(project)
      end
    end

    def clean_up_repository(project)
      job_id = ::Geo::RepositoryCleanupWorker.perform_async(project.id, project.name, project.disk_path, project.repository.storage)

      if job_id
        log_info('Repository clean up scheduled', project_id: project.id, shard: project.repository.storage, disk_path: project.disk_path, job_id: job_id)
      else
        log_error('Could not schedule a repository clean up', project_id: project.id, shard: project.repository.storage, disk_path: project.disk_path)
      end
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
