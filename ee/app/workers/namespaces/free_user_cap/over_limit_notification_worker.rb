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

      def perform_work(*_args); end

      def remaining_work_count(*_args)
        0
      end

      def max_running_jobs
        MAX_RUNNING_JOBS
      end
    end
  end
end
