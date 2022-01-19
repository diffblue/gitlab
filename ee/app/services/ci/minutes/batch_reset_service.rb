# frozen_string_literal: true

module Ci
  module Minutes
    class BatchResetService
      class BatchNotResetError < StandardError
        def initialize(failed_batches)
          @failed_batches = failed_batches
        end

        def message
          'Some namespace shared runner minutes were not reset'
        end

        def sentry_extra_data
          {
            failed_batches: @failed_batches
          }
        end
      end

      BATCH_SIZE = 1000

      def initialize
        @failed_batches = []
      end

      def execute!(ids_range:, batch_size: BATCH_SIZE)
        relation = Namespace.without_project_namespaces.id_in(ids_range)
        relation.each_batch(of: batch_size) do |namespaces|
          reset_ci_minutes!(namespaces)
        end

        raise BatchNotResetError, @failed_batches if @failed_batches.any?
      end

      private

      # ensure that recalculation of extra shared runners minutes occurs in the same
      # transaction as the reset of the namespace statistics. If the transaction fails
      # none of the changes apply but the numbers still remain consistent with each other.
      def reset_ci_minutes!(namespaces)
        Namespace.transaction do
          recalculate_extra_shared_runners_minutes_limits!(namespaces)
          reset_shared_runners_seconds!(namespaces)
          reset_ci_minutes_notifications!(namespaces)
        end
      rescue ActiveRecord::ActiveRecordError => e
        # We cleanup the backtrace for intermediate errors so they remain compact and
        # relevant due to the possibility of having many failed batches.
        @failed_batches << {
          count: namespaces.size,
          first_namespace_id: namespaces.first.id,
          last_namespace_id: namespaces.last.id,
          error_message: e.message,
          error_backtrace: ::Gitlab::BacktraceCleaner.clean_backtrace(e.backtrace)
        }
      end

      # This service is responsible for the logic that recalculates the extra shared runners
      # minutes including how to deal with the cases where shared_runners_minutes_limit is `nil`.
      # We prefer to keep the queries here rather than scatter them across classes.
      # rubocop: disable CodeReuse/ActiveRecord
      def recalculate_extra_shared_runners_minutes_limits!(namespaces)
        return if Feature.enabled?(:ci_use_new_monthly_minutes, default_enabled: :yaml)
        return if Feature.enabled?(:ci_skip_legacy_extra_minutes_recalculation, default_enabled: :yaml)

        namespaces
          .joins(:namespace_statistics)
          .where(namespaces_arel[:extra_shared_runners_minutes_limit].gt(0))
          .where(actual_shared_runners_minutes_limit.gt(0))
          .where(namespaces_statistics_arel[:shared_runners_seconds].gt(actual_shared_runners_minutes_limit * 60))
          .update_all("extra_shared_runners_minutes_limit = #{extra_minutes_left.to_sql} FROM namespace_statistics")
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def extra_minutes_left
        shared_minutes_limit = actual_shared_runners_minutes_limit + namespaces_arel[:extra_shared_runners_minutes_limit]
        used_minutes = arel_function("round", [namespaces_statistics_arel[:shared_runners_seconds] / Arel::Nodes::SqlLiteral.new('60.0')])

        arel_function("greatest", [shared_minutes_limit - used_minutes, 0])
      end

      def actual_shared_runners_minutes_limit
        namespaces_arel.coalesce(
          namespaces_arel[:shared_runners_minutes_limit],
          [::Gitlab::CurrentSettings.shared_runners_minutes.presence, 0].compact
        )
      end

      def namespaces_arel
        Namespace.arel_table
      end

      def namespaces_statistics_arel
        NamespaceStatistics.arel_table
      end

      def arel_function(name, attrs)
        Arel::Nodes::NamedFunction.new(name, attrs)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def reset_shared_runners_seconds!(namespaces)
        NamespaceStatistics
          .for_namespaces(namespaces)
          .where.not(shared_runners_seconds: 0)
          .update_all(shared_runners_seconds: 0, shared_runners_seconds_last_reset: Time.current)

        ::ProjectStatistics
          .for_namespaces(namespaces)
          .where.not(shared_runners_seconds: 0)
          .update_all(shared_runners_seconds: 0, shared_runners_seconds_last_reset: Time.current)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def reset_ci_minutes_notifications!(namespaces)
        namespaces.without_last_ci_minutes_notification.update_all(
          last_ci_minutes_notification_at: nil,
          last_ci_minutes_usage_notification_level: nil
        )
      end
    end
  end
end
