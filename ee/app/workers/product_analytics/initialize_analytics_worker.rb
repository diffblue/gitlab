# frozen_string_literal: true

module ProductAnalytics
  class InitializeAnalyticsWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :product_analytics
    idempotent!
    worker_has_external_dependencies!

    def perform(project_id)
      return if Gitlab::CurrentSettings.jitsu_host.nil? || Gitlab::CurrentSettings.jitsu_project_xid.nil?

      @project = Project.find(project_id)
      ProductAnalytics::JitsuAuthentication.new(jid, @project).create_clickhouse_destination!
    end
  end
end
