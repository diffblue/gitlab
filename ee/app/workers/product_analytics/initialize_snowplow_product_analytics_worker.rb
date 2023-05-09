# frozen_string_literal: true

module ProductAnalytics
  class InitializeSnowplowProductAnalyticsWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :product_analytics
    idempotent!
    worker_has_external_dependencies!

    def perform(project_id)
      @project = Project.find_by_id(project_id)

      return unless ::Feature.enabled?(:product_analytics_snowplow_support, @project)
      return unless @project&.product_analytics_enabled?

      response = Gitlab::HTTP.post(
        "#{::Gitlab::CurrentSettings.product_analytics_configurator_connection_string}/setup-project/gitlab_project_#{project_id}", # rubocop:disable Layout/LineLength
        allow_local_requests: true
      )

      if response.success?
        update_instrumentation_key(Gitlab::Json.parse(response.body)['app_id'])
        track_success
      else
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
          RuntimeError.new(response.body),
          project_id: @project.id
        )
      end
    rescue => e # rubocop:disable Style/RescueStandardError
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, project_id: @project.id)
    end

    private

    def update_instrumentation_key(key)
      @project.project_setting.update!(product_analytics_instrumentation_key: key)
    end

    def track_success
      Gitlab::UsageDataCounters::HLLRedisCounter.track_usage_event(
        'project_initialized_product_analytics',
        @project.id
      )
    end
  end
end
