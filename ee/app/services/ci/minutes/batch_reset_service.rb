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

      def reset_ci_minutes!(namespaces)
        Namespace.transaction do
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
