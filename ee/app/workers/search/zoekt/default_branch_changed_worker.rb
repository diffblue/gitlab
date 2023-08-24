# frozen_string_literal: true

module Search
  module Zoekt
    class DefaultBranchChangedWorker
      include ApplicationWorker
      include Gitlab::EventStore::Subscriber

      data_consistency :delayed
      feature_category :global_search
      urgency :low
      idempotent!

      def handle_event(event)
        return unless ::Feature.enabled?(:index_code_with_zoekt)
        return unless ::License.feature_available?(:zoekt_code_search)

        klass = event.data[:container_type].safe_constantize
        return unless klass == Project

        project = klass.find_by_id(event.data[:container_id])
        return unless project&.use_zoekt?

        project.repository.async_update_zoekt_index
      end
    end
  end
end
