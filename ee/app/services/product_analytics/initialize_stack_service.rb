# frozen_string_literal: true

module ProductAnalytics
  class InitializeStackService < BaseContainerService
    def execute
      return unless Gitlab::CurrentSettings.product_analytics_enabled?
      return unless container.product_analytics_enabled?

      ::ProductAnalytics::InitializeAnalyticsWorker.perform_async(container.id)
    end
  end
end
