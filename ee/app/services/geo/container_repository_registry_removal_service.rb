# frozen_string_literal: true

module Geo
  #
  # Geo::ContainerRepositoryRegistryRemovalService handles container repository removal from a secondary node
  # It handles the removal even when ContainerRepository record doesn't exists
  # This service should work well in cases:
  #  * The selective sync scope is changed and some items have to be removed. The Model record is in place
  #  * The item is removed on primary. We only have the path parameter. The Model record doesn't exist anymore
  #  * The node is out of scope of selective sync. The Model record and the Regsitry record do not exist

  class ContainerRepositoryRegistryRemovalService
    include ::Gitlab::Utils::StrongMemoize
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::LogHelpers

    LEASE_TIMEOUT = 1.hour.freeze

    attr_reader :container_repository_id, :path

    def initialize(container_repository_id, path = nil)
      @container_repository_id = container_repository_id
      @path = path
    end

    def execute
      log_info('Executing')

      try_obtain_lease do
        log_info('Lease obtained')
        destroy_repository if container_repository
        destroy_registry
        log_info('Repository & registry removed')
      end
    rescue SystemCallError => e
      log_error('Could not remove repository', e.message, container_repository_id: container_repository_id)
      raise
    end

    private

    def registry
      replicator.registry
    end
    strong_memoize_attr :registry

    def destroy_repository
      container_repository.delete_tags!
    end

    def container_repository
      if path
        ContainerRepository.new.tap { |cr| cr.path = path }
      else
        ContainerRepository.find_by_id(container_repository_id)
      end
    end
    strong_memoize_attr :container_repository

    def destroy_registry
      log_info('Removing container repository registry', registry_id: registry.id)

      registry.destroy
    end

    def replicator
      Gitlab::Geo::Replicator.for_replicable_params(
        replicable_name: 'container_repository',
        replicable_id: container_repository_id
      )
    end
    strong_memoize_attr :replicator

    def lease_key
      "container_repository_registry_removal_service:#{container_repository_id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
