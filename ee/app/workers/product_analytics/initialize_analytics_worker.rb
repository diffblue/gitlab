# frozen_string_literal: true

module ProductAnalytics
  class InitializeAnalyticsWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :product_analytics_data_management
    idempotent!
    worker_has_external_dependencies!

    # Try only a few times, then give up
    # resetting the redis state so that the job can be retried
    # if the user chooses.
    sidekiq_options retry: 3
    sidekiq_retries_exhausted do
      ::ProductAnalytics::InitializeStackService.new(container: @project).unlock!
    end

    def perform(project_id); end
  end
end
