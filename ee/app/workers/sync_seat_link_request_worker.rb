# frozen_string_literal: true

class SyncSeatLinkRequestWorker
  include ApplicationWorker

  data_consistency :always

  feature_category :sm_provisioning

  # Retry for up to approximately 2 days
  sidekiq_options retry: 20
  sidekiq_retry_in do |count, _exception|
    30.minutes + rand(20.minutes)
  end

  idempotent!
  worker_has_external_dependencies!

  URI_PATH = '/api/v1/seat_links'

  RequestError = Class.new(StandardError)

  def perform(timestamp, license_key, max_historical_user_count, billable_users_count)
    response = Gitlab::HTTP.post(
      URI_PATH,
      base_uri: ::Gitlab::Routing.url_helpers.subscription_portal_url,
      headers: request_headers,
      body: request_body(timestamp, license_key, max_historical_user_count, billable_users_count)
    )

    if response.success?
      reset_license!(response['license']) if response['license']

      save_future_subscriptions(response)
      update_reconciliation!(response)
    else
      raise RequestError, request_error_message(response)
    end
  end

  private

  def reset_license!(license_key)
    if License.current_cloud_license?(license_key)
      License.current.reset.touch(:last_synced_at)
    else
      License.create!(data: license_key, cloud: true, last_synced_at: Time.current)
    end
  rescue StandardError => e
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
  end

  def request_body(timestamp, license_key, max_historical_user_count, billable_users_count)
    Gitlab::SeatLinkData.new(
      timestamp: Time.zone.parse(timestamp),
      key: license_key,
      max_users: max_historical_user_count,
      billable_users_count: billable_users_count
    ).to_json
  end

  def request_headers
    { 'Content-Type' => 'application/json' }
  end

  def request_error_message(response)
    "Seat Link request failed! Code:#{response.code} Body:#{response.body}"
  end

  def update_reconciliation!(response)
    reconciliation = GitlabSubscriptions::UpcomingReconciliation.next

    if response['next_reconciliation_date'].blank? || response['display_alert_from'].blank?
      reconciliation&.destroy!
    else
      attributes = {
        next_reconciliation_date: Date.parse(response['next_reconciliation_date']),
        display_alert_from: Date.parse(response['display_alert_from'])
      }

      if reconciliation
        reconciliation.update!(attributes)
      else
        GitlabSubscriptions::UpcomingReconciliation.create!(attributes)
      end
    end
  end

  def save_future_subscriptions(response)
    future_subscriptions = response['future_subscriptions'].presence || []

    Gitlab::CurrentSettings.current_application_settings.update!(future_subscriptions: future_subscriptions)
  rescue StandardError => err
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(err)
  end
end
