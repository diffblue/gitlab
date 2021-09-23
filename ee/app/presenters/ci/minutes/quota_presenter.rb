# frozen_string_literal: true

module Ci
  module Minutes
    class QuotaPresenter < Gitlab::View::Presenter::Simple
      include Gitlab::Utils::StrongMemoize

      presents Quota, as: :quota

      Report = Struct.new(:used, :limit, :status)

      # Status of the monthly allowance being used.
      def monthly_minutes_report
        Report.new(quota.monthly_minutes_used, minutes_limit, report_status)
      end

      def monthly_percent_used
        return 0 unless quota.enabled?
        return 0 if quota.monthly_minutes == 0

        100 * quota.monthly_minutes_used.to_i / quota.monthly_minutes
      end

      # Status of any purchased minutes used.
      def purchased_minutes_report
        status = quota.purchased_minutes_used_up? ? :over_quota : :under_quota
        Report.new(quota.purchased_minutes_used, quota.purchased_minutes, status)
      end

      def purchased_percent_used
        return 0 unless quota.enabled?
        return 0 if quota.purchased_minutes == 0

        100 * quota.purchased_minutes_used.to_i / quota.purchased_minutes
      end

      def display_minutes_available_data?
        display_shared_runners_data? && !quota.namespace_unlimited_minutes?
      end

      def display_shared_runners_data?
        quota.namespace_root? && any_project_enabled?
      end

      def any_project_enabled?
        strong_memoize(:any_project_enabled) do
          quota.namespace.any_project_with_shared_runners_enabled?
        end
      end

      private

      def report_status
        return :disabled unless quota.enabled?

        quota.monthly_minutes_used_up? ? :over_quota : :under_quota
      end

      def minutes_limit
        return _('Not supported') unless display_shared_runners_data?

        if display_minutes_available_data?
          quota.monthly_minutes
        else
          _('Unlimited')
        end
      end
    end
  end
end
