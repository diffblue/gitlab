# frozen_string_literal: true

module GitlabSubscriptions
  class ScheduleRefreshSeatsWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :seat_cost_management
    data_consistency :always
    urgency :low

    idempotent!

    def perform
      return unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

      GitlabSubscriptions::RefreshSeatsWorker.perform_with_capacity
    end
  end
end
