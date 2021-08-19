# frozen_string_literal: true

# This class provides current status of Shared Runners minutes usage for a namespace
# taking in consideration the monthly minutes allowance that Gitlab.com provides and
# any possible purchased minutes.

module Ci
  module Minutes
    class Quota
      include Gitlab::Utils::StrongMemoize

      Report = Struct.new(:used, :limit, :status)

      def initialize(namespace)
        @namespace = namespace
      end

      def enabled?
        namespace_root? && total_minutes.nonzero?
      end

      # Status of the monthly allowance being used.
      def monthly_minutes_report
        Report.new(monthly_minutes_used, minutes_limit, report_status)
      end

      def monthly_percent_used
        return 0 unless enabled?
        return 0 if monthly_minutes == 0

        100 * monthly_minutes_used.to_i / monthly_minutes
      end

      # Status of any purchased minutes used.
      def purchased_minutes_report
        status = purchased_minutes_used_up? ? :over_quota : :under_quota
        Report.new(purchased_minutes_used, purchased_minutes, status)
      end

      def purchased_percent_used
        return 0 unless enabled?
        return 0 if purchased_minutes == 0

        100 * purchased_minutes_used.to_i / purchased_minutes
      end

      def minutes_used_up?
        enabled? && total_minutes_used >= total_minutes
      end

      def percent_total_minutes_remaining
        return 0 if total_minutes == 0

        100 * total_minutes_remaining.to_i / total_minutes
      end

      def current_balance
        total_minutes.to_i - total_minutes_used
      end

      def display_shared_runners_data?
        namespace_root? && any_project_enabled?
      end

      def display_minutes_available_data?
        display_shared_runners_data? && total_minutes.nonzero?
      end

      def total_minutes
        strong_memoize(:total_minutes) do
          monthly_minutes + purchased_minutes
        end
      end

      def total_minutes_used
        strong_memoize(:total_minutes_used) do
          namespace.shared_runners_seconds.to_i / 60
        end
      end

      def any_project_enabled?
        strong_memoize(:any_project_enabled) do
          namespace.any_project_with_shared_runners_enabled?
        end
      end

      private

      attr_reader :namespace

      def minutes_limit
        return _('Not supported') unless display_shared_runners_data?

        if display_minutes_available_data?
          monthly_minutes
        else
          _('Unlimited')
        end
      end

      def report_status
        return :disabled unless enabled?

        monthly_minutes_used_up? ? :over_quota : :under_quota
      end

      def total_minutes_remaining
        [current_balance, 0].max
      end

      def monthly_minutes_used_up?
        return false unless enabled?

        monthly_minutes_used >= monthly_minutes
      end

      def purchased_minutes_used_up?
        return false unless enabled?

        any_minutes_purchased? && purchased_minutes_used >= purchased_minutes
      end

      def monthly_minutes_used
        total_minutes_used - purchased_minutes_used
      end

      def monthly_minutes_available?
        total_minutes_used <= monthly_minutes
      end

      def purchased_minutes_used
        return 0 if no_minutes_purchased? || monthly_minutes_available?

        total_minutes_used - monthly_minutes
      end

      def no_minutes_purchased?
        purchased_minutes == 0
      end

      def any_minutes_purchased?
        purchased_minutes > 0
      end

      def monthly_minutes
        strong_memoize(:monthly_minutes) do
          (namespace.shared_runners_minutes_limit || ::Gitlab::CurrentSettings.shared_runners_minutes).to_i
        end
      end

      def purchased_minutes
        strong_memoize(:purchased_minutes) do
          namespace.extra_shared_runners_minutes_limit.to_i
        end
      end

      def namespace_root?
        strong_memoize(:namespace_root) do
          namespace.root?
        end
      end
    end
  end
end
