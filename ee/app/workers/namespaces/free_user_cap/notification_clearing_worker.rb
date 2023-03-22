# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class NotificationClearingWorker
      include ApplicationWorker
      include LimitedCapacity::Worker

      feature_category :user_management
      data_consistency :always
      sidekiq_options retry: false
      idempotent!

      MAX_RUNNING_JOBS = 5
      BATCH_SIZE = 1
      SCHEDULING_BUFFER = 24

      def perform_work(...)
        return unless feature_enabled?

        next_batch.map(&:namespace_id).each do |namespace_id|
          clear namespace_id: namespace_id
        end
      end

      def max_running_jobs
        return 0 unless feature_enabled?

        MAX_RUNNING_JOBS
      end

      def remaining_work_count(...)
        (notified_namespaces_to_be_checked.limit(MAX_RUNNING_JOBS * BATCH_SIZE).count / BATCH_SIZE).ceil
      end

      private

      def next_batch
        Namespace::Detail.transaction do
          Namespace::Detail.find_by_sql next_batch_sql # rubocop: disable CodeReuse/ActiveRecord
        end
      end

      def clear(namespace_id:)
        namespace = Namespace.find_by id: namespace_id # rubocop: disable CodeReuse/ActiveRecord
        return unless namespace

        Gitlab::ApplicationContext.push(namespace: namespace)
        log_service_response ClearOverLimitNotificationService.execute(root_namespace: namespace)
      end

      def log_service_response(result)
        return unless result.is_a? ServiceResponse

        %i[status message].each do |key|
          log_extra_metadata_on_done key, result[key]
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def next_batch_sql
        <<~SQL.squish
          UPDATE "namespace_details"
          SET "next_over_limit_check_at" = to_timestamp(#{schedule.to_i})
            WHERE "namespace_details"."namespace_id" IN (#{locked_item_ids_sql})
            RETURNING *
        SQL
      end

      def locked_item_ids_sql
        notified_namespaces_to_be_checked
          .order_next_over_limit_check_nulls_first
          .limit(BATCH_SIZE)
          .lock('FOR UPDATE SKIP LOCKED')
          .select(:namespace_id)
          .to_sql
      end

      def notified_namespaces_to_be_checked
        Namespace::Detail.where(free_user_cap_over_limit_notified_at: ..due_at)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def schedule
        SCHEDULING_BUFFER.hours.from_now
      end

      def due_at
        SCHEDULING_BUFFER.hours.ago
      end

      def feature_enabled?
        ::Feature.enabled? :free_user_cap_clear_over_limit_notification_flags
      end
    end
  end
end
