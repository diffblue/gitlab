# frozen_string_literal: true

module Ci
  module Minutes
    class ResetUsageService < BaseService
      def initialize(namespace)
        @namespace = namespace
      end

      def execute
        Ci::Minutes::NamespaceMonthlyUsage.reset_current_usage(@namespace)
        reset_legacy_usage

        ::Ci::Minutes::RefreshCachedDataService.new(@namespace).execute

        true
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def reset_legacy_usage
        NamespaceStatistics.where(namespace: @namespace).update_all(
          shared_runners_seconds: 0,
          shared_runners_seconds_last_reset: Time.current)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
