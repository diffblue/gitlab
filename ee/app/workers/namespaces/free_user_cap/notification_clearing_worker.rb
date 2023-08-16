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

      def perform_work(...); end

      def max_running_jobs
        MAX_RUNNING_JOBS
      end

      def remaining_work_count(...)
        0
      end
    end
  end
end
