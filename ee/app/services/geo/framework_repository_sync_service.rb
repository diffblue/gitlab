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

    LEASE_TIMEOUT    = 8.hours
    LEASE_KEY_PREFIX = 'geo_sync_ssf_service'

    def initialize(replicator)
      @replicator = replicator
      @repository = replicator.repository
      @new_repository = false
    end

    def execute
      try_obtain_lease do
        log_info("Started #{replicable_name} sync")

        sync_repository

        log_info("Finished #{replicable_name} sync")
      end

      # Must happen after releasing lease to avoid race condition where the new
      # job cannot obtain the lease.
      do_reschedule_sync if reschedule_sync?
    end

    def sync_repository
      start_registry_sync!
      fetch_repository
      mark_sync_as_successful
    rescue Gitlab::Git::Repository::NoRepository => e
      fail_registry_sync!('Invalid repository', e)

      log_info('Expiring caches')
      repository.after_create
    rescue Gitlab::Shell::Error, Gitlab::Git::BaseError => e
      # In some cases repository does not exist, the only way to know about this
      # is to parse the error text. If the repository does not exist on the
      # primary, then the state on this secondary matches the primary, and
      # therefore the repository is successfully synced.
      if e.message.include?(replicator.class.no_repo_message)
        log_info('Repository is not found, marking it as successfully synced')
        mark_sync_as_successful(missing_on_primary: true)
      else
        fail_registry_sync!('Error syncing repository', e)
      end

    ensure
      expire_repository_caches
      execute_housekeeping
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
      target_repository.fetch_as_mirror(replicator.remote_url, forced: true, http_authorization_header: replicator.jwt_authentication_header)
    end

    # Clone a Geo repository using JWT authentication mechanism
    #
    # @param [Repository] target_repository specify a different temporary repository (default: current repository)
    def clone_geo_mirror(target_repository: repository)
      target_repository.clone_as_mirror(replicator.remote_url, http_authorization_header: replicator.jwt_authentication_header)
    end

    def mark_sync_as_successful(missing_on_primary: false)
      log_info("Marking #{replicable_name} sync as successful")

      registry = replicator.registry
      registry.missing_on_primary = missing_on_primary
      persisted = registry.synced!

      set_reschedule_sync unless persisted

      log_info("Finished #{replicable_name} sync",
               download_time_s: download_time_in_seconds)
    end

    def start_registry_sync!
      log_info("Marking #{replicable_name} sync as started")

      registry.start!
    end

    def fail_registry_sync!(message, error)
      log_error(message, error)

      registry = replicator.registry
      registry.failed!(message: message, error: error)
    end

    def download_time_in_seconds
      (Time.current.to_f - registry.last_synced_at.to_f).round(3)
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

    def execute_housekeeping
      return unless replicator.class.housekeeping_enabled?

      task = new_repository? ? :gc : nil
      service = Repositories::HousekeepingService.new(replicator.housekeeping_model_record, task)
      service.increment!

      return if task.nil? && !service.needed?

      service.execute do
        replicator.before_housekeeping
      end
    rescue Repositories::HousekeepingService::LeaseTaken
      # best-effort
    end

    def set_reschedule_sync
      @reschedule_sync = true
    end

    def reschedule_sync?
      @reschedule_sync
    end

    def do_reschedule_sync
      log_info("Reschedule the sync because an updated event was processed during the sync")

      replicator.reschedule_sync
    end

    def replicable_name
      replicator.replicable_name
    end

    def update_root_ref
      authorization = ::Gitlab::Geo::RepoSyncRequest.new(
        scope: repository.full_path
      ).authorization

      repository.update_root_ref(replicator.remote_url, authorization)
    end
  end
end
