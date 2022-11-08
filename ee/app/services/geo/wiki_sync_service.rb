# frozen_string_literal: true

module Geo
  class WikiSyncService < RepositoryBaseSyncService
    self.type = :wiki

    private

    def sync_repository
      start_registry_sync!
      fetch_repository
      mark_sync_as_successful
    rescue Gitlab::Git::Repository::NoRepository => e
      log_info('Setting force_to_redownload flag')
      fail_registry_sync!('Invalid wiki', e, force_to_redownload_wiki: true)
    rescue Gitlab::Shell::Error, Gitlab::Git::BaseError, Wiki::CouldNotCreateWikiError => e
      # In some cases repository does not exist, the only way to know about this is to parse the error text.
      # If it does not exist we should consider it as successfully downloaded.
      if e.message.include?(Gitlab::GitAccessWiki.error_message(:no_repo))
        if repository_presumably_exists_on_primary?
          log_info('Wiki is not found, but it seems to exist on the primary')
          fail_registry_sync!('Wiki is not found', e)
        else
          log_info('Wiki is not found, marking it as successfully synced')
          mark_sync_as_successful(missing_on_primary: true)
        end
      else
        fail_registry_sync!('Error syncing wiki repository', e)
      end

    ensure
      expire_repository_caches
    end

    def repository
      project.wiki.repository
    end

    def ensure_repository
      project.wiki.create_wiki_repository
    end

    def expire_repository_caches
      log_info('Expiring caches')
      repository.after_sync
    end

    def fail_registry_sync!(message, error, attrs = {})
      log_error(message, error)

      within_transaction do
        project_repository_registry.fail_sync!(:wiki, message, error, attrs)

        wiki_repository_registry.force_to_redownload = attrs.fetch(:force_to_redownload, false)
        wiki_repository_registry.failed!(message: message, error: error)
      end
    end

    def start_registry_sync!
      log_info("Marking wiki sync as started")

      within_transaction do
        project_repository_registry.start_sync!(:wiki)
        wiki_repository_registry.start!
      end
    end

    def mark_sync_as_successful(missing_on_primary: false)
      log_info("Marking wiki sync as successful")

      persisted =
        within_transaction do
          wiki_repository_registry.force_to_redownload = false
          wiki_repository_registry.missing_on_primary = missing_on_primary

          project_repository_registry.finish_sync!(:wiki, missing_on_primary, primary_checksummed?) &&
            wiki_repository_registry.synced!
        end

      reschedule_sync unless persisted

      log_info("Finished wiki sync",
              download_time_s: download_time_in_seconds)
    end

    def download_time_in_seconds
      (Time.current.to_f - last_synced_at.to_f).round(3)
    end

    def last_synced_at
      wiki_repository_registry.last_synced_at || project_repository_registry.last_wiki_synced_at
    end

    def primary_checksum
      project.wiki_repository_state&.verification_checksum || project.repository_state&.wiki_verification_checksum
    end

    def force_to_redownload
      wiki_repository_registry.force_to_redownload || project_repository_registry.force_to_redownload_wiki
    end

    def retries
      [wiki_repository_registry.retry_count, project_repository_registry.wiki_retry_count.to_i].max
    end

    def project_repository_registry
      @project_repository_registry ||=
        Geo::ProjectRegistry.find_or_initialize_by(project_id: project.id) # rubocop: disable CodeReuse/ActiveRecord
    end
    alias_method :registry, :project_repository_registry

    def wiki_repository_registry
      @wiki_repository_registry ||=
        Geo::ProjectWikiRepositoryRegistry.find_or_initialize_by(project_id: project.id) # rubocop: disable CodeReuse/ActiveRecord
    end

    def within_transaction(&block)
      project_repository_registry.class.transaction(&block)
    end
  end
end
