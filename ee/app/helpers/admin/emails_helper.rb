# frozen_string_literal: true

module Admin
  module EmailsHelper
    include Gitlab::Utils::StrongMemoize

    def send_emails_from_admin_area_feature_available?
      License.feature_available?(:send_emails_from_admin_area) || GitlabSubscriptions::Features.usage_ping_feature?(:send_emails_from_admin_area)
    end

    def admin_emails_are_currently_rate_limited?
      admin_emails_rate_limit_ttl.present?
    end

    def admin_emails_rate_limit_ttl
      strong_memoize(:admin_emails_rate_limit_ttl) do
        Gitlab::ExclusiveLease.new(
          Admin::EmailService::LEASE_KEY,
          timeout: Admin::EmailService::DEFAULT_LEASE_TIMEOUT
        ).ttl
      end
    end

    def admin_emails_rate_limited_alert
      return '' unless admin_emails_are_currently_rate_limited?

      _("An email notification was recently sent from the admin panel. Please wait %{wait_time_in_words} before attempting to send another message.") %
        { wait_time_in_words: distance_of_time_in_words(admin_emails_rate_limit_ttl) }
    end
  end
end
