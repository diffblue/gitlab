# frozen_string_literal: true

module Zoekt
  class IndexerWorker
    TIMEOUT = 2.hours

    include ApplicationWorker

    data_consistency :always
    include Gitlab::ExclusiveLeaseHelpers

    feature_category :global_search
    urgency :throttled
    idempotent!

    def perform(project_id)
      return unless ::Feature.enabled?(:index_code_with_zoekt)
      return unless ::License.feature_available?(:zoekt_code_search)

      project = Project.find(project_id)
      return true unless project.use_zoekt?
      return true unless project.repository_exists?
      return true if project.empty_repo?

      in_lock("#{self.class.name}/#{project_id}", ttl: (TIMEOUT + 1.minute), retries: 0) do
        project.repository.update_zoekt_index!
      end
    end
  end
end
