# frozen_string_literal: true

module Search
  module Zoekt
    class NamespaceIndexerWorker
      include ApplicationWorker

      # Must be always otherwise we risk race condition where it does not think that indexing is enabled yet for the
      # namespace.
      data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency
      feature_category :global_search
      idempotent!
      pause_control :zoekt

      def perform(namespace_id, operation, shard_id = nil)
        return unless ::Feature.enabled?(:index_code_with_zoekt)

        namespace = Namespace.find(namespace_id)

        # Symbols convert to string when queuing in Sidekiq
        case operation.to_sym
        when :index
          index_projects(namespace)
        when :delete
          remove_projects(namespace, shard_id: shard_id)
        end
      end

      private

      def index_projects(namespace)
        return unless namespace.use_zoekt?

        namespace.all_projects.find_in_batches do |batch|
          ::Zoekt::IndexerWorker.bulk_perform_async_with_contexts(
            batch,
            arguments_proc: ->(project) { project.id },
            context_proc: ->(project) { { project: project } }
          )
        end
      end

      def remove_projects(namespace, shard_id:)
        namespace.all_projects.find_in_batches do |batch|
          ::Search::Zoekt::DeleteProjectWorker.bulk_perform_async_with_contexts(
            batch,
            arguments_proc: ->(project) do
              [
                project.root_namespace&.id,
                project.id,
                shard_id
              ]
            end,
            context_proc: ->(project) { { project: project } }
          )
        end
      end
    end
  end
end
