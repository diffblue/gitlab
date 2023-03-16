# frozen_string_literal: true

# Activating self-managed instances
# Part of Cloud Licensing https://gitlab.com/groups/gitlab-org/-/epics/1735
module GitlabSubscriptions
  class ActivateService
    include Gitlab::Utils::StrongMemoize

    ERROR_MESSAGES = {
      not_self_managed: 'Not self-managed instance'
    }.freeze

    def execute(activation_code, automated: false)
      return error(ERROR_MESSAGES[:not_self_managed]) if Gitlab.com?

      response = client.activate(activation_code, automated: automated)

      return response unless response[:success]

      license = find_or_initialize_cloud_license(response[:license_key])
      license.last_synced_at = Time.current

      if license.save
        save_future_subscriptions(response[:future_subscriptions])

        {
          success: true,
          license: license,
          future_subscriptions: application_settings.future_subscriptions
        }
      else
        error(license.errors.full_messages)
      end
    rescue StandardError => e
      error(e.message)
    end

    private

    def client
      Gitlab::SubscriptionPortal::Client
    end

    def error(message)
      { success: false, errors: Array(message) }
    end

    def find_or_initialize_cloud_license(license_key)
      return License.current.reset if License.current_cloud_license?(license_key)

      License.new(data: license_key, cloud: true)
    end

    def save_future_subscriptions(future_subscriptions)
      future_subscriptions = future_subscriptions.presence || []

      application_settings.update!(future_subscriptions: future_subscriptions)
    rescue StandardError => err
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(err)
    end

    def application_settings
      strong_memoize(:application_settings) do
        Gitlab::CurrentSettings.current_application_settings
      end
    end
  end
end
