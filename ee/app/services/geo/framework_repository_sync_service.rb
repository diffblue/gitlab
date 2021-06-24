# frozen_string_literal: true

require 'securerandom'

module Geo
  # This class is similar to RepositoryBaseSyncService
  # but it works in a scope of Self-Service-Framework
  class FrameworkRepositorySyncService
    include ExclusiveLeaseGuard
    include ::Gitlab::ShellAdapter
    include ::Gitlab::Geo::LogHelpers
    include Delay

    attr_reader :replicator, :repository

    delegate :registry, to: :replicator

    GEO_REMOTE_NAME  = 'geo'
    LEASE_TIMEOUT    = 8.hours
    LEASE_KEY_PREFIX = 'geo_sync_ssf_service'
    RETRIES_BEFORE_REDOWNLOAD = 5

    def initialize(replicator)
      @replicator = replicator
      @repository = replicator.repository
    end

    def execute
      try_obtain_lease do
        log_info("Started #{replicable_name} sync")

        sync_repository

        log_info("Finished #{replicable_name} sync")
      end
    end

    def sync_repository
      start_registry_sync!
      fetch_repository
      update_root_ref
      mark_sync_as_successful
    rescue Gitlab::Git::Repository::NoRepository => e
      log_info('Marking the repository for a forced re-download')
      fail_registry_sync!('Invalid repository', e, force_to_redownload: true)

      log_info('Expiring caches')
      repository.after_create
    rescue Gitlab::Shell::Error, Gitlab::Git::BaseError => e
      # In some cases repository does not exist, the only way to know about this is to parse the error text.
      # If it does not exist we should consider it as successfully downloaded.
      if e.message.include?(replicator.class.git_access_class.error_message(:no_repo))
        log_info('Repository is not found, marking it as successfully synced')
        mark_sync_as_successful(missing_on_primary: true)
      else
        fail_registry_sync!('Error syncing repository', e)
      end

    ensure
      expire_repository_caches
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{replicable_name}:#{replicator.model_record.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    private

    def fetch_repository
      log_info("Trying to fetch #{replicable_name}")
      clean_up_temporary_repository

      if should_be_redownloaded?
        redownload_repository
        @new_repository = true
      elsif repository.exists?
        fetch_geo_mirror(repository)
      else
        ensure_repository
        fetch_geo_mirror(repository)
        @new_repository = true
      end
    end

    def redownload_repository
      log_info("Redownloading #{replicable_name}")

      if fetch_snapshot_into_temp_repo
        set_temp_repository_as_main

        return
      end

      log_info("Attempting to fetch repository via git")

      # `git fetch` needs an empty bare repository to fetch into
      temp_repo.create_repository
      fetch_geo_mirror(temp_repo)

      set_temp_repository_as_main
    ensure
      clean_up_temporary_repository
    end

    def current_node
      ::Gitlab::Geo.current_node
    end

    def fetch_geo_mirror(repository)
      # Fetch the repository, using a JWT header for authentication
      repository.with_config(replicator.jwt_authentication_header) do
        repository.fetch_as_mirror(replicator.remote_url, remote_name: GEO_REMOTE_NAME, forced: true)
      end
    end

    # Use snapshotting for redownloads *only* when enabled.
    #
    # If writes happen to the repository while snapshotting, it may be
    # returned in an inconsistent state. However, a subsequent git fetch
    # will be enqueued by the log cursor, which should resolve any problems
    # it is possible to fix.
    def fetch_snapshot_into_temp_repo
      # Snapshots will miss the data that are shared in object pools, and snapshotting should
      # be avoided to guard against data loss.
      return if replicator.model_record.pool_repository

      log_info("Attempting to fetch repository via snapshot")

      temp_repo.create_from_snapshot(
        ::Gitlab::Geo.primary_node.snapshot_url(temp_repo),
        ::Gitlab::Geo::RepoSyncRequest.new(scope: ::Gitlab::Geo::API_SCOPE).authorization
      )
    rescue StandardError => err
      log_error('Snapshot attempt failed', err)
      false
    end

    def mark_sync_as_successful(missing_on_primary: false)
      log_info("Marking #{replicable_name} sync as successful")

      registry = replicator.registry
      registry.force_to_redownload = false
      registry.missing_on_primary = missing_on_primary
      persisted = registry.synced!

      reschedule_sync unless persisted

      log_info("Finished #{replicable_name} sync",
               download_time_s: download_time_in_seconds)
    end

    def start_registry_sync!
      log_info("Marking #{replicable_name} sync as started")

      registry.start!
    end

    def fail_registry_sync!(message, error, force_to_redownload: false)
      log_error(message, error)

      registry = replicator.registry
      registry.force_to_redownload = force_to_redownload
      registry.failed!(message, error)

      repository.clean_stale_repository_files
    end

    def download_time_in_seconds
      (Time.current.to_f - registry.last_synced_at.to_f).round(3)
    end

    def disk_path_temp
      # We use "@" as it's not allowed to use it in a group or project name
      @disk_path_temp ||= "@geo-temporary/#{repository.disk_path}"
    end

    def deleted_disk_path_temp
      @deleted_path ||= "@failed-geo-sync/#{repository.disk_path}"
    end

    def temp_repo
      @temp_repo ||= ::Repository.new(repository.full_path, repository.container, shard: repository.shard, disk_path: disk_path_temp, repo_type: repository.repo_type)
    end

    def clean_up_temporary_repository
      exists = gitlab_shell.repository_exists?(repository_storage, disk_path_temp + '.git')

      if exists && !gitlab_shell.remove_repository(repository_storage, disk_path_temp)
        raise Gitlab::Shell::Error, "Temporary #{replicable_name} can not be removed"
      end
    end

    def set_temp_repository_as_main
      log_info(
        "Setting newly downloaded repository as main",
        storage_shard: repository_storage,
        temp_path: disk_path_temp,
        deleted_disk_path_temp: deleted_disk_path_temp,
        disk_path: repository.disk_path
      )

      # Remove the deleted path in case it exists, but it may not be there
      gitlab_shell.remove_repository(repository_storage, deleted_disk_path_temp)

      # Make sure we have the most current state of exists?
      repository.expire_exists_cache

      # Move the current canonical repository to the deleted path for reference
      if repository.exists?
        unless gitlab_shell.mv_repository(repository_storage, repository.disk_path, deleted_disk_path_temp)
          raise Gitlab::Shell::Error, 'Can not move original repository out of the way'
        end
      end

      # Move the temporary repository to the canonical path
      unless gitlab_shell.mv_repository(repository_storage, disk_path_temp, repository.disk_path)
        raise Gitlab::Shell::Error, 'Can not move temporary repository to canonical location'
      end

      # Purge the original repository
      unless gitlab_shell.remove_repository(repository_storage, deleted_disk_path_temp)
        raise Gitlab::Shell::Error, 'Can not remove outdated main repository'
      end
    end

    def repository_storage
      replicator.model_record.repository_storage
    end

    def new_repository?
      @new_repository
    end

    def ensure_repository
      repository.create_if_not_exists
    end

    def expire_repository_caches
      log_info('Expiring caches for repository')
      repository.after_sync
    end

    def should_be_redownloaded?
      return true if registry.force_to_redownload

      registry.retry_count > RETRIES_BEFORE_REDOWNLOAD
    end

    def reschedule_sync
      log_info("Reschedule the sync because a RepositoryUpdateEvent was processed during the sync")

      replicator.reschedule_sync
    end

    def replicable_name
      replicator.replicable_name
    end

    def update_root_ref
      authorization = ::Gitlab::Geo::RepoSyncRequest.new(
        scope: repository.full_path
      ).authorization

      repository.update_root_ref(GEO_REMOTE_NAME, replicator.remote_url, authorization)
    end
  end
end
