# frozen_string_literal: true

require 'securerandom'

module Geo
  class RepositoryBaseSyncService
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::ProjectLogHelpers
    include ::Gitlab::ShellAdapter
    include Delay

    class << self
      attr_accessor :type
    end

    attr_reader :project

    LEASE_TIMEOUT    = 8.hours
    LEASE_KEY_PREFIX = 'geo_sync_service'
    RETRIES_BEFORE_REDOWNLOAD = 10

    def initialize(project)
      @project = project
      @new_repository = false
    end

    def execute
      try_obtain_lease do
        log_info("Started #{type} sync")

        sync_repository

        log_info("Finished #{type} sync")
      end
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{type}:#{project.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    def repository
      raise NotImplementedError, 'Define a reference to the repository'
    end

    private

    def fetch_repository
      log_info("Trying to fetch #{type}")
      clean_up_temporary_repository

      # TODO: Remove this as part of
      # https://gitlab.com/gitlab-org/gitlab/-/issues/9803
      # This line is a workaround to avoid broken project repos in Geo
      # secondaries after migrating repos to a different storage.
      repository.expire_exists_cache

      if should_be_redownloaded?
        redownload_repository
        @new_repository = true
      elsif repository.exists?
        fetch_geo_mirror
      else
        if Feature.enabled?('geo_use_clone_on_first_sync')
          clone_geo_mirror

          @new_repository = true
        else
          ensure_repository

          # Because we ensure a repository exists by this point, we need to
          # mark it as new, even if fetching the mirror fails, we should run
          # housekeeping to enable object deduplication to run
          @new_repository = true
          fetch_geo_mirror
        end
      end

      update_root_ref
    end

    def redownload_repository
      log_info("Redownloading #{type}")

      if fetch_snapshot_into_temp_repo
        set_temp_repository_as_main

        return
      end

      log_info("Attempting to fetch repository via git")

      if Feature.enabled?('geo_use_clone_on_first_sync')
        clone_geo_mirror(target_repository: temp_repo)
      else
        # `git fetch` needs an empty bare repository to fetch into
        temp_repo.create_repository
        fetch_geo_mirror(target_repository: temp_repo)
      end

      set_temp_repository_as_main
    ensure
      clean_up_temporary_repository
    end

    def current_node
      ::Gitlab::Geo.current_node
    end

    # Updates an existing repository using JWT authentication mechanism
    #
    # @param [Repository] target_repository specify a different temporary repository (default: current repository)
    def fetch_geo_mirror(target_repository: repository)
      # Fetch the repository, using a JWT header for authentication
      target_repository.fetch_as_mirror(remote_url,
                                       forced: true,
                                       http_authorization_header: jwt_authentication_header)
    end

    # Clone a Geo repository using JWT authentication mechanism
    #
    # @param [Repository] target_repository specify a different temporary repository (default: current repository)
    def clone_geo_mirror(target_repository: repository)
      target_repository.clone_as_mirror(remote_url,
                                        http_authorization_header: jwt_authentication_header)
    end

    # Build a JWT header for authentication
    def jwt_authentication_header
      ::Gitlab::Geo::RepoSyncRequest.new(
        scope: repository.full_path
      ).authorization
    end

    def remote_url
      Gitlab::Geo.primary_node.repository_url(repository)
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
      return if project.pool_repository

      log_info("Attempting to fetch repository via snapshot")

      temp_repo.create_from_snapshot(
        ::Gitlab::Geo.primary_node.snapshot_url(temp_repo),
        ::Gitlab::Geo::RepoSyncRequest.new(scope: ::Gitlab::Geo::API_SCOPE).authorization
      )
    rescue StandardError => err
      log_error('Snapshot attempt failed', err)
      false
    end

    def primary_checksummed?
      primary_checksum.present?
    end

    def primary_checksum
      # Must be overridden in the children classes
    end

    def should_be_redownloaded?
      return true if force_to_redownload

      retries.present? && retries > RETRIES_BEFORE_REDOWNLOAD && retries.odd?
    end

    def reschedule_sync
      log_info("Reschedule #{type} sync because a RepositoryUpdateEvent was processed during the sync")

      ::Geo::ProjectSyncWorker.perform_async(
        project.id,
        sync_repository: type.repository?,
        sync_wiki: type.wiki?
      )
    end

    def type
      @type ||= self.class.type.to_s.inquiry
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
      exists = gitlab_shell.repository_exists?(project.repository_storage, disk_path_temp + '.git')

      if exists && !gitlab_shell.remove_repository(project.repository_storage, disk_path_temp)
        raise Gitlab::Shell::Error, "Temporary #{type} can not be removed"
      end
    end

    def set_temp_repository_as_main
      log_info(
        "Setting newly downloaded repository as main",
        storage_shard: project.repository_storage,
        temp_path: disk_path_temp,
        deleted_disk_path_temp: deleted_disk_path_temp,
        disk_path: repository.disk_path
      )

      # Remove the deleted path in case it exists, but it may not be there
      gitlab_shell.remove_repository(project.repository_storage, deleted_disk_path_temp)

      # Make sure we have the most current state of exists?
      repository.expire_exists_cache

      # Move the current canonical repository to the deleted path for reference
      if repository.exists?
        unless gitlab_shell.mv_repository(project.repository_storage, repository.disk_path, deleted_disk_path_temp)
          raise Gitlab::Shell::Error, 'Can not move original repository out of the way'
        end
      end

      # Move the temporary repository to the canonical path

      unless gitlab_shell.mv_repository(project.repository_storage, disk_path_temp, repository.disk_path)
        raise Gitlab::Shell::Error, 'Can not move temporary repository to canonical location'
      end

      # Purge the original repository
      unless gitlab_shell.remove_repository(project.repository_storage, deleted_disk_path_temp)
        raise Gitlab::Shell::Error, 'Can not remove outdated main repository'
      end
    end

    def new_repository?
      @new_repository
    end

    # If repository has a verification checksum, we can assume that it existed on the primary
    def repository_presumably_exists_on_primary?
      return false unless project.repository_state

      checksum = project.repository_state.public_send("#{type}_verification_checksum") # rubocop:disable GitlabSecurity/PublicSend
      checksum && checksum != Gitlab::Git::Repository::EMPTY_REPOSITORY_CHECKSUM
    end

    def update_root_ref
      authorization = ::Gitlab::Geo::RepoSyncRequest.new(
        scope: repository.full_path
      ).authorization

      repository.update_root_ref(remote_url, authorization)
    end
  end
end
