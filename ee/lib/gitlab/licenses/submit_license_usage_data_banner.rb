# frozen_string_literal: true

module Gitlab
  module Licenses
    class SubmitLicenseUsageDataBanner
      SUBMIT_LICENSE_USAGE_DATA_BANNER = 'submit_license_usage_data_banner'

      def reset
        return unless has_non_trial_offline_cloud_license?
        return unless same_day_or_end_of_month?

        Gitlab::CurrentSettings.update(license_usage_data_exported: false)
        Users::Callout.with_feature_name(SUBMIT_LICENSE_USAGE_DATA_BANNER).delete_all
      end

      private

      def has_non_trial_offline_cloud_license?
        return false if Gitlab::CurrentSettings.should_check_namespace_plan?
        return false unless Feature.enabled?(:automated_email_provision)
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
    end
  end
end
