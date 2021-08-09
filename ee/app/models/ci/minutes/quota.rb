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
        strong_memoize(:enabled) do
          namespace_eligible? && total_minutes.nonzero?
        end
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

      def total_minutes
        @total_minutes ||= monthly_minutes + purchased_minutes
      end

      def total_minutes_used
        @total_minutes_used ||= namespace.shared_runners_seconds.to_i / 60
      end

      def percent_total_minutes_remaining
        return 0 if total_minutes == 0

        100 * total_minutes_remaining.to_i / total_minutes
      end

      def namespace_eligible?
        strong_memoize(:namespace_eligible) do
          namespace.root?
        end
      end

      def current_balance
        total_minutes.to_i - total_minutes_used
      end

      def any_project_enabled?
        strong_memoize(:any_project_enabled) do
          namespace.any_project_with_shared_runners_enabled?
        end
      end

      private

      def minutes_limit
        return monthly_minutes if enabled? && any_project_enabled?

        if namespace_eligible? && any_project_enabled?
          _('Unlimited')
        else
          _('Not supported')
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
        @monthly_minutes ||= (namespace.shared_runners_minutes_limit || ::Gitlab::CurrentSettings.shared_runners_minutes).to_i
      end

      def purchased_minutes
        @purchased_minutes ||= namespace.extra_shared_runners_minutes_limit.to_i
      end

      attr_reader :namespace
    end
  end
end
