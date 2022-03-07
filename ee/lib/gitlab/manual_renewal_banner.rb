# frozen_string_literal: true

module Gitlab
  class ManualRenewalBanner < Gitlab::ManualBanner
    def display_error_version?
      actionable.expired?
    end

    private

    def require_notification?
      return false unless actionable&.will_expire?
      return false if ::License.future_dated.present?

      within_notification_window?
    end

    def within_notification_window?
      (actionable.expires_at - REMINDER_DAYS) <= Date.today
    end

    def banner_subject
      plan = actionable.plan.titleize
      expires_at = actionable.expires_at.to_s

      if display_error_version?
        _('Your %{plan} subscription expired on %{expiry_date}') % { plan: plan, expiry_date: expires_at }
      else
        _('Your %{plan} subscription expires on %{expiry_date}') % { plan: plan, expiry_date: expires_at }
      end
    end

    def banner_body
      if display_error_version?
        _(
          'Your subscription is now expired. To renew, export your license usage file and email it to ' \
          '%{renewal_service_email}. A new license will be emailed to the email address registered in the ' \
          '%{customers_dot}. You can add this license to your instance. To use Free tier, remove your ' \
          'current license.'
        ).html_safe % { renewal_service_email: renewal_service_email, customers_dot: customers_dot_url }
      else
        _(
          'To renew, export your license usage file and email it to %{renewal_service_email}. ' \
          'A new license will be emailed to the email address registered in the %{customers_dot}. ' \
          'You can add this license to your instance.'
        ).html_safe % { renewal_service_email: renewal_service_email, customers_dot: customers_dot_url }
      end
    end
  end
end
