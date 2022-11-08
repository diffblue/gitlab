# frozen_string_literal: true

module Geo
  class RepositorySyncService < RepositoryBaseSyncService
    self.type = :repository

    private

    def sync_repository
      start_registry_sync!
      fetch_repository
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

    def execute_housekeeping
      Geo::ProjectHousekeepingService.new(project, new_repository: new_repository?).execute
    end

    def fail_registry_sync!(message, error, attrs = {})
      log_error(message, error)
      registry.fail_sync!(:repository, message, error, attrs)
    end

    def start_registry_sync!
      log_info("Marking repository sync as started")
      registry.start_sync!(:repository)
    end

    def mark_sync_as_successful(missing_on_primary: false)
      log_info("Marking repository sync as successful")

      persisted = registry.finish_sync!(:repository, missing_on_primary, primary_checksummed?)

      reschedule_sync unless persisted

      log_info("Finished repository sync",
              update_delay_s: update_delay_in_seconds,
              download_time_s: download_time_in_seconds)
    end

    def primary_checksum
      project.repository_state&.repository_verification_checksum
    end

    def update_delay_in_seconds
      return unless project.last_repository_updated_at

      (registry.last_repository_successful_sync_at.to_f - project.last_repository_updated_at.to_f).round(3)
    end

    def download_time_in_seconds
      (registry.last_repository_successful_sync_at.to_f - registry.last_repository_synced_at.to_f).round(3)
    end

    def force_to_redownload
      registry.force_to_redownload_repository
    end

    def retries
      registry.repository_retry_count.to_i
    end

    def registry
      @registry ||=
        Geo::ProjectRegistry.find_or_initialize_by(project_id: project.id) # rubocop: disable CodeReuse/ActiveRecord
    end
  end
end
