# frozen_string_literal: true

module Ci
  class UpstreamProjectsSubscriptionsCleanupWorker
    include ApplicationWorker

    data_consistency :always

    feature_category :continuous_integration
    idempotent!

    def perform(project_id)
      project = Project.find_by_id(project_id)

      return unless project
      return if project.licensed_feature_available?(:ci_project_subscriptions)

      project.upstream_project_subscriptions.destroy_all # rubocop: disable Cop/DestroyAll
    end
  end
end
