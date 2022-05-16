# frozen_string_literal: true

module Ci
  module Minutes
    class UsagePresenter < Gitlab::View::Presenter::Simple
      include Gitlab::Utils::StrongMemoize

      presents Usage, as: :usage

      Report = Struct.new(:used, :limit, :status)

      # Status of the monthly allowance being used.
      def monthly_minutes_report
        Report.new(usage.monthly_minutes_used, minutes_limit, report_status)
      end

      def monthly_percent_used
        return 0 unless usage.limit_enabled?
        return 0 if usage.limit.monthly == 0

        100 * usage.monthly_minutes_used.to_i / usage.limit.monthly
      end

      # Status of any purchased minutes used.
      def purchased_minutes_report
        status = usage.purchased_minutes_used_up? ? :over_quota : :under_quota
        Report.new(usage.purchased_minutes_used, usage.limit.purchased, status)
      end

      def purchased_percent_used
        return 0 unless usage.limit_enabled?
        return 0 unless usage.limit.any_purchased?

        100 * usage.purchased_minutes_used.to_i / usage.limit.purchased
      end

      def display_minutes_available_data?
        display_shared_runners_data? && usage.limit_enabled?
      end

      def display_shared_runners_data?
        usage.namespace.root? && any_project_enabled?
      end

      def any_project_enabled?
        strong_memoize(:any_project_enabled) do
          usage.namespace.any_project_with_shared_runners_enabled?
        end
      end

      private

      def report_status
        return :disabled unless usage.limit_enabled?

        usage.monthly_minutes_used_up? ? :over_quota : :under_quota
      end

      def minutes_limit
        return _('Not supported') unless display_shared_runners_data?

        if display_minutes_available_data?
          usage.limit.monthly
        else
          _('Unlimited')
        end
      end
    end
  end
end
