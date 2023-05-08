# frozen_string_literal: true

module GitlabSubscriptions
  class RefreshSeatsWorker
    include ApplicationWorker
    include LimitedCapacity::Worker

    feature_category :seat_cost_management
    data_consistency :sticky
    urgency :low

    idempotent!

    MAX_RUNNING_JOBS = 6

    def perform_work
      return if ::Gitlab::Database.read_only?
      return unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

      subscription = find_next_subscription
      return unless subscription

      subscription.refresh_seat_attributes
      subscription.save!
    end

    def remaining_work_count(*args)
      subscriptions_requiring_refresh(max_running_jobs + 1).count
    end

    def max_running_jobs
      MAX_RUNNING_JOBS
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def find_next_subscription
      GitlabSubscription.transaction do
        subscription = subscriptions_requiring_refresh
          .preload_for_refresh_seat
          .order("last_seat_refresh_at ASC NULLS FIRST")
          .lock('FOR UPDATE SKIP LOCKED')
          .first

        next unless subscription

        # Update the last_seat_refresh_at so the same subscription isn't picked up in parallel
        subscription.update_column(:last_seat_refresh_at, Time.current)

        subscription
      end
    end

    def subscriptions_requiring_refresh(limit = 1)
      GitlabSubscription.requiring_seat_refresh(limit)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
