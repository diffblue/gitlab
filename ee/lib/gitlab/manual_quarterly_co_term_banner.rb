# frozen_string_literal: true

module Gitlab
  class ManualQuarterlyCoTermBanner
    include ::Gitlab::Utils::StrongMemoize

    REMINDER_DAYS = 14.days

    def initialize(upcoming_reconciliation)
      @upcoming_reconciliation = upcoming_reconciliation
    end

    def display?
      return false if Gitlab::CurrentSettings.should_check_namespace_plan?
      return false unless ::License.current&.offline_cloud_license?
      return false unless ::License.current.seat_reconciliation?

      require_notification?
    end

    def title
      _('A quarterly reconciliation is due on %{date}') % { date: formatted_date }
    end

    def body
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

    def display_error_version?
      next_reconciliation_date < current_date
    end

    private

    attr_reader :upcoming_reconciliation

    def require_notification?
      return false unless upcoming_reconciliation

      (next_reconciliation_date - REMINDER_DAYS) <= current_date
    end

    def next_reconciliation_date
      strong_memoize(:next_reconciliation_date) do
        upcoming_reconciliation.next_reconciliation_date
      end
    end

    def current_date
      strong_memoize(:current_date) do
        Date.current
      end
    end

    def formatted_date
      strong_memoize(:formatted_date) do
        next_reconciliation_date.strftime('%Y-%m-%d')
      end
    end

    def renewal_service_email
      email = Gitlab::SubscriptionPortal::RENEWAL_SERVICE_EMAIL
      "<a href='mailto:#{email}'>#{email}</a>".html_safe
    end

    def customers_dot_url
      edit_account_url = ::Gitlab::Routing.url_helpers.subscription_portal_edit_account_url

      %(<a href="#{edit_account_url}">Customers Portal</a>).html_safe
    end
  end
end
