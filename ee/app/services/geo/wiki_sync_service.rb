# frozen_string_literal: true

module Geo
  class WikiSyncService < RepositoryBaseSyncService
    self.type = :wiki

    private

    def sync_repository
      return if ::Geo::ProjectWikiRepositoryReplicator.enabled?

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
  end
end
