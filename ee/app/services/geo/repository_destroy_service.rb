# frozen_string_literal: true

module Geo
  class RepositoryDestroyService
    include ::Gitlab::Geo::LogHelpers
    include ::Gitlab::Utils::StrongMemoize

    attr_reader :id, :name, :disk_path, :repository_storage

    # There is a possibility that the replicable's record does not exist
    # anymore. In this case, you need to pass the optional parameters
    # explicitly.
    def initialize(id, name = nil, disk_path = nil, repository_storage = nil)
      @id = id
      @name = name
      @disk_path = disk_path
      @repository_storage = repository_storage
    end

    def async_execute
      GeoRepositoryDestroyWorker.perform_async(id, name, disk_path, repository_storage)
    end

    def execute
      destroy_project
      destroy_registry_entries
    rescue StandardError => e
      log_error('Could not destroy repository', e, project_id: id, shard: repository_storage, disk_path: disk_path)
      destroy_registry_entries
      raise
    end

    private

    def destroy_project
      # We should skip if we had to rebuild the project, but we don't
      # have the information that our service class requires.
      return if project.is_a?(Geo::DeletedProject) && !project.valid?

      ::Projects::DestroyService.new(project, nil).geo_replicate
    end

    def destroy_registry_entries
      ::Geo::ProjectRegistry.model_id_in(id).delete_all

      log_info('Registry entries removed', project_id: id)
    end

    def project
      strong_memoize(:project) do
        Project.find(id)
      rescue ActiveRecord::RecordNotFound => e
        # When cleaning up project/registries, there are some cases where
        # the replicable record does not exist anymore. So, we try to
        # rebuild it with only what our service class requires.
        log_error('Could not find project', e.message)

        ::Geo::DeletedProject.new(
          id: id,
          name: name,
          disk_path: disk_path,
          repository_storage: repository_storage
        )
      end
    end
  end
end
