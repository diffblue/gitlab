# frozen_string_literal: true

module ProductAnalytics
  class InitializeAnalyticsWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :product_analytics
    idempotent!
    worker_has_external_dependencies!

    # Try only a few times, then give up
    # resetting the redis state so that the job can be retried
    # if the user chooses.
    sidekiq_options retry: 3
    sidekiq_retries_exhausted do
      ::ProductAnalytics::InitializeStackService.new(container: @project).unlock!
    end

    def perform(project_id)
      @project = Project.find_by_id(project_id)

      return unless @project&.product_analytics_enabled?

      settings = ProductAnalytics::Settings.for_project(@project)
      return if settings.jitsu_host.nil? || settings.jitsu_project_xid.nil?

      ProductAnalytics::JitsuAuthentication.new(jid, @project).create_clickhouse_destination!
      ::ProductAnalytics::InitializeStackService.new(container: @project).unlock!
    end
  end
end
