# frozen_string_literal: true

module Geo
  class DesignRepositorySyncService < RepositoryBaseSyncService
    self.type = :design

    private

    def sync_repository
      start_registry_sync!
      fetch_repository
      mark_sync_as_successful
    rescue Gitlab::Git::Repository::NoRepository => e
      log_info('Marking the design repository for a forced re-download')
      fail_registry_sync!('Invalid design repository', e, force_to_redownload: true)
    rescue Gitlab::Shell::Error, Gitlab::Git::BaseError => e
      # In some cases repository does not exist, the only way to know about this is to parse the error text.
      # If it does not exist we should consider it as successfully downloaded.
      if e.message.include? Gitlab::GitAccessDesign.error_message(:no_repo)
        log_info('Design repository is not found, marking it as successfully synced')
        mark_sync_as_successful(missing_on_primary: true)
      else
        fail_registry_sync!('Error syncing design repository', e)
      end

    ensure
      expire_repository_caches
    end

    def repository
      project.design_repository
    end

    def ensure_repository
      repository.create_if_not_exists
    end

    def expire_repository_caches
      log_info('Expiring caches for design repository')
      repository.after_sync
    end

    def fail_registry_sync!(message, error, attrs = {})
      log_error(message, error)

      registry.fail_sync!(message, error, attrs)
    end

    def start_registry_sync!
      log_info("Marking design sync as started")
      registry.start_sync!
    end

    def mark_sync_as_successful(missing_on_primary: false)
      log_info("Marking design sync as successful")

      persisted = registry.finish_sync!(missing_on_primary)

      reschedule_sync unless persisted

      log_info("Finished design sync", download_time_s: download_time_in_seconds)
    end

    def reschedule_sync
      log_info("Reschedule design sync because a RepositoryUpdateEvent was processed during the sync")

      ::Geo::DesignRepositorySyncWorker.perform_async(project.id)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def registry
      @registry ||= Geo::DesignRegistry.find_or_initialize_by(project_id: project.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def download_time_in_seconds
      (Time.current.to_f - registry.last_synced_at.to_f).round(3)
    end

    def redownload?
      return false if Feature.enabled?(:geo_deprecate_redownload)

      registry.should_be_redownloaded?
    end
  end
end
