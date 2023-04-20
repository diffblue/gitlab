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

      def perform(namespace_id, operation)
        return unless ::Feature.enabled?(:index_code_with_zoekt)

        namespace = Namespace.find(namespace_id)
        return unless namespace.use_zoekt?

        # Symbols convert to string when queuing in Sidekiq
        index_projects(namespace) if operation.to_s == 'index'
      end

      private

      def index_projects(namespace)
        namespace.all_projects.find_in_batches do |batch|
          ::Zoekt::IndexerWorker.bulk_perform_async_with_contexts(
            batch,
            arguments_proc: ->(project) { project.id },
            context_proc: ->(project) { { project: project } }
          )
        end
      end
    end
  end
end
