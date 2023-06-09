# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class OverLimitNotificationWorker
      include ApplicationWorker
      include LimitedCapacity::Worker

      feature_category :user_management
      data_consistency :always
      sidekiq_options retry: false
      idempotent!

      MAX_RUNNING_JOBS = 1
      BATCH_SIZE = 100
      SCHEDULE_BUFFER_IN_HOURS = 24

      def perform_work(*_args)
        ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries do
          Array.wrap(next_batch).map(&:namespace_id).each do |namespace_id|
            notify namespace_id: namespace_id
          end
        end
      end

      def remaining_work_count(*_args)
        (Namespace::Detail.scheduled_for_over_limit_check.limit(MAX_RUNNING_JOBS * BATCH_SIZE).count / BATCH_SIZE).ceil
      end

      def max_running_jobs
        return 0 unless enforce_over_limit_mails?

        MAX_RUNNING_JOBS
      end

      private

      def notify(namespace_id:)
        return unless enforce_over_limit_mails?

        namespace = Namespace.find_by id: namespace_id # rubocop: disable CodeReuse/ActiveRecord

        NotifyOverLimitService.execute(root_namespace: namespace) if namespace
      end

      def next_batch
        Namespace::Detail.transaction do
          ids = item_ids
          Namespace::Detail.find_by_sql(perform_update_sql(ids)) if ids.present? # rubocop: disable CodeReuse/ActiveRecord
        end
      end

      def perform_update_sql(ids)
        # The alternative to setting the timestamp would be using something like
        # SET "next_over_limit_check_at" = NOW() + INTERVAL '#{SCHEDULE_BUFFER_IN_HOURS} hours'
        # that makes it quite hared to spec, since the DB doesn't freeze time along with ruby
        <<~SQL.squish
          UPDATE "namespace_details"
          SET "next_over_limit_check_at" = to_timestamp(#{schedule.to_i})
            WHERE "namespace_details"."namespace_id" IN (#{ids.join(', ')})
            RETURNING *
        SQL
      end

      def item_ids
        Namespace::Detail
          .not_over_limit_notified
          .for_over_limit_check(BATCH_SIZE, namespace_ids)
          .pluck(:namespace_id) # rubocop: disable CodeReuse/ActiveRecord
      end

      def namespace_ids
        ::Namespaces::FreeUserCap::EnforceableGroupsFinder.new.execute.select :id
      end

      def schedule
        SCHEDULE_BUFFER_IN_HOURS.hours.from_now
      end

      def enforce_over_limit_mails?
        ::Namespaces::FreeUserCap.over_user_limit_mails_enabled? && ::Gitlab::CurrentSettings.dashboard_limit_enabled?
      end
    end
  end
end
