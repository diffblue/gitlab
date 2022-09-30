# frozen_string_literal: true

module ProductAnalytics
  class InitializeStackService < BaseContainerService
    def execute
      return unless ::Feature.enabled?(:jitsu_connection_proof_of_concept, container.group)

      ::ProductAnalytics::InitializeAnalyticsWorker.perform_async(container.id)
    end
  end
end
