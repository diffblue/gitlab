# frozen_string_literal: true

module Gitlab
  class ManualQuarterlyCoTermBanner < Gitlab::ManualBanner
    include ::Gitlab::Utils::StrongMemoize

    def display_error_version?
      actionable.next_reconciliation_date < Date.current
    end

    private

    def require_notification?
      return false unless actionable

      (actionable.next_reconciliation_date - REMINDER_DAYS) <= Date.current
    end

    def formatted_date
      strong_memoize(:formatted_date) do
        actionable.next_reconciliation_date.strftime('%Y-%m-%d')
      end
    end

    def banner_subject
      _('A quarterly reconciliation is due on %{date}') % { date: formatted_date }
    end

    def banner_body
      if display_error_version?
        _(
          'You have more active users than are allowed by your license. GitLab must now reconcile your ' \
            'subscription. To complete this process, export your license usage file and email it to ' \
            '%{renewal_service_email}. A new license will be emailed to the email address registered in the ' \
            '%{customers_dot}. You can add this license to your instance.'
        ).html_safe % { renewal_service_email: renewal_service_email, customers_dot: customers_dot_url }
      else
        _(
          'You have more active users than are allowed by your license. Before %{date} GitLab ' \
            'must reconcile your subscription. To complete this process, export your license usage file and email ' \
            'it to %{renewal_service_email}. A new license will be emailed to the email address registered in ' \
            'the %{customers_dot}. You can add this license to your instance.'
        ).html_safe % { date: formatted_date, renewal_service_email: renewal_service_email, customers_dot: customers_dot_url }
      end
    end
  end
end
