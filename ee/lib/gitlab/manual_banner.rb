# frozen_string_literal: true

module Gitlab
  class ManualBanner
    REMINDER_DAYS = 14.days

    def initialize(actionable:)
      @actionable = actionable
    end

    def display?
      return false if Gitlab::CurrentSettings.should_check_namespace_plan?
      return false unless Feature.enabled?(:automated_email_provision)
      return false unless ::License.current&.offline_cloud_license?

      require_notification?
    end

    def subject
      return unless display?

      banner_subject
    end

    def body
      return unless display?

      banner_body
    end

    def display_error_version?
      raise NotImplementedError
    end

    private

    attr_reader :actionable

    def require_notification?
      raise NotImplementedError
    end

    def banner_subject
      raise NotImplementedError
    end

    def banner_body
      raise NotImplementedError
    end

    def renewal_service_email
      email = Gitlab::SubscriptionPortal::RENEWAL_SERVICE_EMAIL
      "<a href='mailto:#{email}'>#{email}</a>".html_safe
    end

    def customers_dot_url
      "<a href='#{EE::SUBSCRIPTIONS_EDIT_ACCOUNT_URL}'>Customers Portal</a>".html_safe
    end
  end
end
