# frozen_string_literal: true

module Search
  module Zoekt
    class DeleteProjectWorker
      include ApplicationWorker
      include Gitlab::ExclusiveLeaseHelpers

      TIMEOUT = 1.minute

      data_consistency :delayed

      feature_category :global_search
      urgency :throttled
      idempotent!
      pause_control :zoekt

      def perform(root_namespace_id, project_id)
        return unless ::Feature.enabled?(:index_code_with_zoekt)
        return unless ::License.feature_available?(:zoekt_code_search)

        in_lock("#{self.class.name}/#{project_id}", ttl: TIMEOUT, retries: 0) do
          ::Gitlab::Search::Zoekt::Client.delete(root_namespace_id: root_namespace_id, project_id: project_id)
        end
      end
    end
  end
end
