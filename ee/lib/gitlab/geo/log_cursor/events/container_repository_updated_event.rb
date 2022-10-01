# frozen_string_literal: true

module Gitlab
  module Geo
    module LogCursor
      module Events
        class ContainerRepositoryUpdatedEvent
          include BaseEvent

          def process
            if replicable_container_repository?
              registry.save if registry.new_record?

              job_id = ::Geo::ContainerRepositorySyncWorker.perform_async(event.container_repository_id)
            end

            log_event(job_id)
          end

          private

          def replicable_container_repository?
            id = event.container_repository_id

            strong_memoize(:"replicable_container_repository_#{id}") do
              next false unless ::Geo::ContainerRepositoryRegistry.replication_enabled?

              # If a registry exists, then it *should* be replicated. The
              # registry will be removed by the delete event or
              # RegistryConsistencyWorker if it should no longer be replicated.
              #
              # This early exit helps keep processing of update events
              # efficient.
              next true if registry.persisted?

              Gitlab::Geo.current_node.container_repositories_include?(id)
            end
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def registry
            @registry ||= ::Geo::ContainerRepositoryRegistry.find_or_initialize_by(
              container_repository_id: event.container_repository_id
            )
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def log_event(job_id)
            super(
              'Docker Repository update',
              container_repository_id: event.container_repository_id,
              replication_enabled: ::Geo::ContainerRepositoryRegistry.replication_enabled?,
              replicable_container_repository: replicable_container_repository?,
              project_id: registry.container_repository.project_id,
              job_id: job_id)
          end
        end
      end
    end
  end
end
