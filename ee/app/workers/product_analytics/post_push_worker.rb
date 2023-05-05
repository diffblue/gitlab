# frozen_string_literal: true

module ProductAnalytics
  class PostPushWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :product_analytics
    idempotent!

    def perform(project_id, newrev)
      @project = Project.find_by_id(project_id)
      @commit = @project.repository.commit(newrev)

      track_event if commit_has_new_dashboard?
    end

    private

    def commit_has_new_dashboard?
      @commit.deltas.any? do |delta|
        delta.new_path.start_with?(".gitlab/analytics/dashboards/") && delta.new_file
      end
    end

    def track_event
      Gitlab::UsageDataCounters::HLLRedisCounter.track_usage_event(
        :project_created_analytics_dashboard,
        @project.id
      )
    end
  end
end
