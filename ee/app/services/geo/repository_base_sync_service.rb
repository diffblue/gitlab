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

      # TODO: Remove this as part of
      # https://gitlab.com/gitlab-org/gitlab/-/issues/9803
      # This line is a workaround to avoid broken project repos in Geo
      # secondaries after migrating repos to a different storage.
      repository.expire_exists_cache

      if repository.exists?
        fetch_geo_mirror
      elsif Feature.enabled?('geo_use_clone_on_first_sync')
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

      update_root_ref
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

    # rubocop: disable CodeReuse/ActiveRecord
    def registry
      @registry ||= Geo::ProjectRegistry.find_or_initialize_by(project_id: project.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def mark_sync_as_successful(missing_on_primary: false)
      log_info("Marking #{type} sync as successful")

      persisted = registry.finish_sync!(type, missing_on_primary, primary_checksummed?)

      reschedule_sync unless persisted

      log_info("Finished #{type} sync",
              update_delay_s: update_delay_in_seconds,
              download_time_s: download_time_in_seconds)
    end

    def primary_checksummed?
      primary_checksum.present?
    end

    def primary_checksum
      project.repository_state&.public_send("#{type}_verification_checksum") # rubocop:disable GitlabSecurity/PublicSend
    end

    def reschedule_sync
      log_info("Reschedule #{type} sync because a RepositoryUpdateEvent was processed during the sync")

      ::Geo::ProjectSyncWorker.perform_async(
        project.id,
        sync_repository: type.repository?,
        sync_wiki: type.wiki?
      )
    end

    def start_registry_sync!
      log_info("Marking #{type} sync as started")
      registry.start_sync!(type)
    end

    def fail_registry_sync!(message, error, attrs = {})
      log_error(message, error)

      registry.fail_sync!(type, message, error, attrs)
    end

    def type
      @type ||= self.class.type.to_s.inquiry
    end

    def update_delay_in_seconds
      # We don't track the last update time of repositories and Wiki
      # separately in the main database
      return unless project.last_repository_updated_at

      (last_successful_sync_at.to_f - project.last_repository_updated_at.to_f).round(3)
    end

    def download_time_in_seconds
      (last_successful_sync_at.to_f - last_synced_at.to_f).round(3)
    end

    def last_successful_sync_at
      registry.public_send("last_#{type}_successful_sync_at") # rubocop:disable GitlabSecurity/PublicSend
    end

    def last_synced_at
      registry.public_send("last_#{type}_synced_at") # rubocop:disable GitlabSecurity/PublicSend
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
