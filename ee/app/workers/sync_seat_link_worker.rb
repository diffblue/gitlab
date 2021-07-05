# frozen_string_literal: true

class SyncSeatLinkWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :license

  # Retry for up to approximately 17 hours
  sidekiq_options retry: 12, dead: false

  def perform
    return unless seat_link_data.should_sync_seats?

    SyncSeatLinkRequestWorker.perform_async(
      seat_link_data.timestamp.iso8601,
      seat_link_data.key,
      seat_link_data.max_users,
      seat_link_data.billable_users_count
    )
  end

  private

  def seat_link_data
    @seat_link_data ||= Gitlab::SeatLinkData.new
  end
end
