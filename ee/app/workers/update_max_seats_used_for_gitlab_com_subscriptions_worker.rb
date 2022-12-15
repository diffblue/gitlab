# frozen_string_literal: true

class UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :subscription_cost_management
  worker_resource_boundary :cpu

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    return if ::Gitlab::Database.read_only?
    return unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

    GitlabSubscription.with_a_paid_hosted_plan.preload_for_refresh_seat.find_in_batches(batch_size: 100) do |subscriptions|
      tuples = []
      current_timestamp = Time.current

      subscriptions.each do |subscription|
        subscription.refresh_seat_attributes!

        max_seat_used_changed_at = if subscription.max_seats_used_changed?
                                     current_timestamp
                                   else
                                     subscription.max_seats_used_changed_at
                                   end

        tuples << [
          subscription.id,
          subscription.max_seats_used,
          subscription.seats_in_use,
          subscription.seats_owed,
          max_seat_used_changed_at.present? ? "timestamp '#{max_seat_used_changed_at}'" : 'NULL::timestamp'
        ]
      rescue ActiveRecord::QueryCanceled => e
        track_error(e, subscription)
      end

      if tuples.present?
        GitlabSubscription.connection.execute <<-EOF
          UPDATE gitlab_subscriptions AS s
          SET max_seats_used = v.max_seats_used,
              seats_in_use = v.seats_in_use,
              seats_owed = v.seats_owed,
              max_seats_used_changed_at = v.max_seats_used_changed_at
          FROM (VALUES #{tuples.map { |tuple| "(#{tuple.join(', ')})" }.join(', ')}) AS v(id, max_seats_used, seats_in_use, seats_owed, max_seats_used_changed_at)
          WHERE s.id = v.id
        EOF
      end
    end
  end

  def self.last_enqueue_time
    Sidekiq::Cron::Job.find('update_max_seats_used_for_gitlab_com_subscriptions_worker')&.last_enqueue_time
  end

  private

  def track_error(error, subscription)
    Gitlab::ErrorTracking.track_exception(
      error,
      gitlab_subscription_id: subscription.id,
      namespace_id: subscription.namespace_id
    )
  end
end
