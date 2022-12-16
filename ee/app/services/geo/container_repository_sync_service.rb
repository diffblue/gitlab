# frozen_string_literal: true

module Geo
  class ContainerRepositorySyncService
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::ContainerRepositoryLogHelpers

    LEASE_TIMEOUT = 8.hours.freeze
    LEASE_KEY = 'geo_container_sync'

    attr_reader :container_repository

    def initialize(container_repository)
      @container_repository = container_repository
    end

    def execute
      # We need this call to avoid possible race condition when new event has come but
      # the other one still is in process.
      registry.pending!

      try_obtain_lease do
        sync_repository
      end
    end

    def sync_repository
      log_info('Marking sync as started')
      registry.start!

      Geo::ContainerRepositorySync.new(container_repository).execute

      mark_sync_as_successful

      log_info('Finished sync')
    rescue StandardError => e
      fail_registry_sync!("Container repository sync failed", e)
    end

    private

    def mark_sync_as_successful
      persisted = registry.synced!

      reschedule_sync unless persisted
    end

    def reschedule_sync
      log_info("Reschedule container sync because an update event was processed during the sync")

      Geo::ContainerRepositorySyncWorker.perform_async(container_repository.id)
    end

    def fail_registry_sync!(message, error)
      log_error(message, error)

      registry.failed!(message: message, error: error)
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY}:#{container_repository.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def registry
      @registry ||= Geo::ContainerRepositoryRegistry.find_or_initialize_by(
        container_repository_id: container_repository.id
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
