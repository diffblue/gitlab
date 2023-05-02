# frozen_string_literal: true

module Gitlab
  module Licenses
    class SubmitLicenseUsageDataBanner
      SUBMIT_LICENSE_USAGE_DATA_BANNER = 'submit_license_usage_data_banner'

      def initialize(user = nil)
        @user = user
      end

      def reset
        return unless has_non_trial_offline_cloud_license?
        return unless same_day_or_end_of_month?

        Gitlab::CurrentSettings.update(license_usage_data_exported: false)
        Users::Callout.with_feature_name(SUBMIT_LICENSE_USAGE_DATA_BANNER).delete_all
      end

      def display?
        return false unless user&.can_admin_all_resources?
        return false unless has_non_trial_offline_cloud_license?
        return false if Date.current < ::License.current.starts_at + 1.month
        return false if user.dismissed_callout?(feature_name: SUBMIT_LICENSE_USAGE_DATA_BANNER)

        true
      end

      def title
        return unless display?

        _('Report your license usage data to GitLab')
      end

      def body
        return unless display?

        _(
          'Per your subscription agreement with GitLab, you must report your license usage data on a monthly basis. ' \
          'GitLab uses this data to keep your subscription up to date. To report your license usage data, export ' \
          'your license usage file and email it to %{renewal_service_email}. If you need an updated license, ' \
          'GitLab will send the license to the email address registered in the %{customers_dot}, and you can ' \
          'upload this license to your instance.'
        ).html_safe % { renewal_service_email: renewal_service_email, customers_dot: customers_dot_url }
      end

      def dismissable?
        Gitlab::CurrentSettings.license_usage_data_exported?
      end

      private

      attr_reader :user

      def has_non_trial_offline_cloud_license?
        return false if Gitlab::CurrentSettings.should_check_namespace_plan?
        return false unless ::License.current&.offline_cloud_license?
        return false if ::License.current.trial?

        true
      end

      def same_day_or_end_of_month?
        current_date = Date.current
        start_date = ::License.current.starts_at

        current_date.day == start_date.day ||
          (current_date == current_date.end_of_month && start_date.day > current_date.day)
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
end
