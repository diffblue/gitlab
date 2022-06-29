# frozen_string_literal: true

module Gitlab
  class SeatLinkData
    include Gitlab::Utils::StrongMemoize

    attr_reader :timestamp, :key, :max_users, :billable_users_count

    delegate :to_json, to: :data

    # All fields can be passed to initializer to override defaults. In some cases, the defaults
    # are preferable, like for SyncSeatLinkWorker, to determine seat link data, and in others,
    # like for SyncSeatLinkRequestWorker, the params are passed because the values from when
    # the job was enqueued are necessary.
    def initialize(timestamp: nil, key: default_key, max_users: nil, billable_users_count: nil)
      @current_time = Time.current
      @timestamp = timestamp || historical_data&.recorded_at || current_time
      @key = key
      @max_users = max_users || default_max_count
      @billable_users_count = billable_users_count || default_billable_users_count
    end

    def sync
      return unless should_sync_seats?

      SyncSeatLinkWorker.perform_async
    end

    def should_sync_seats?
      return false unless license&.cloud_license?
      return false if license.offline_cloud_license?

      !license.trial? && license.expires_at.present? # Skip sync if license has no expiration
    end

    private

    attr_reader :current_time

    def data
      {
        gitlab_version: Gitlab::VERSION,
        timestamp: timestamp.iso8601,
        license_key: key,
        max_historical_user_count: max_users,
        billable_users_count: billable_users_count,
        hostname: Gitlab.config.gitlab.host,
        instance_id: Gitlab::CurrentSettings.uuid
      }
    end

    def license
      ::License.current
    end

    def default_key
      license&.data
    end

    def default_max_count
      license&.historical_max(to: timestamp)
    end

    def historical_data
      strong_memoize(:historical_data) do
        to_timestamp = timestamp || current_time

        license&.historical_data(to: to_timestamp)&.order(:recorded_at)&.last
      end
    end

    def default_billable_users_count
      historical_data&.active_user_count
    end
  end
end
