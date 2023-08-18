# frozen_string_literal: true

module Search
  module Zoekt
    class ProjectTransferWorker
      include ApplicationWorker

      pause_control :zoekt

      feature_category :global_search
      idempotent!
      data_consistency :delayed
      urgency :throttled

      def perform(project_id, old_namespace_id)
        return unless ::Feature.enabled?(:index_code_with_zoekt)
        return unless ::License.feature_available?(:zoekt_code_search)

        project = Project.find_by_id(project_id)
        old_namespace = Namespace.find_by_id(old_namespace_id)

        return false unless project && old_namespace

        if old_namespace.use_zoekt?
          Search::Zoekt::DeleteProjectWorker.perform_async(old_namespace.root_ancestor.id, project_id)
        end

        return unless project.use_zoekt?

        ::Zoekt::IndexerWorker.perform_async(project_id)
      end
    end
  end
end
