# frozen_string_literal: true

module Geo
  class RepositorySyncService < RepositoryBaseSyncService
    self.type = :repository

    private

    def sync_repository
      start_registry_sync!
      fetch_repository
      update_root_ref
      mark_sync_as_successful
    rescue Gitlab::Git::Repository::NoRepository => e
      log_info('Setting force_to_redownload flag')
      fail_registry_sync!('Invalid repository', e, force_to_redownload_repository: true)

      log_info('Expiring caches')
      project.repository.after_create
    rescue Gitlab::Shell::Error, Gitlab::Git::BaseError => e
      # In some cases repository does not exist, the only way to know about this is to parse the error text.
      if e.message.include?(Gitlab::GitAccessProject.error_message(:no_repo))
        if repository_presumably_exists_on_primary?
          log_info('Repository is not found, but it seems to exist on the primary')
          fail_registry_sync!('Repository is not found', e)
        else
          log_info('Repository is not found, marking it as successfully synced')
          mark_sync_as_successful(missing_on_primary: true)
        end
      else
        fail_registry_sync!('Error syncing repository', e)
      end

    ensure
      expire_repository_caches
      execute_housekeeping
    end

    def expire_repository_caches
      log_info('Expiring caches')
      project.repository.after_sync
    end

    def repository
      project.repository
    end

    def ensure_repository
      project.ensure_repository
    end

    def update_root_ref
      authorization = ::Gitlab::Geo::RepoSyncRequest.new(
        scope: repository.full_path
      ).authorization

      repository.update_root_ref(GEO_REMOTE_NAME, remote_url, authorization)
    end

    def execute_housekeeping
      Geo::ProjectHousekeepingService.new(project, new_repository: new_repository?).execute
    end
  end
end
