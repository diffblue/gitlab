# frozen_string_literal: true

module Geo
  class RepositoryCleanupWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers
    include ::Gitlab::Utils::StrongMemoize

    loggable_arguments 1, 2, 3

    def perform(project_id, name, disk_path, storage_name)
      return unless current_node.secondary?

      if can_clean_up?(project_id)
        Geo::RepositoryDestroyService.new(project_id, name, disk_path, storage_name).execute

        log_info('Repositories cleaned up', project_id: project_id, shard: storage_name, disk_path: disk_path)
      else
        log_info('Skipping repositories clean up', project_id: project_id, shard: storage_name, disk_path: disk_path)
      end
    end

    private

    def can_clean_up?(project_id)
      !current_node.projects_include?(project_id)
    end

    def current_node
      strong_memoize(:current_node) do
        Gitlab::Geo.current_node
      end
    end
  end
end
