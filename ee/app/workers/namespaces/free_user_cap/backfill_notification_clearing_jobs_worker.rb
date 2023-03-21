# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class BackfillNotificationClearingJobsWorker
      include ApplicationWorker

      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      feature_category :user_management
      urgency :low
      data_consistency :always
      idempotent!

      def perform(...)
        NotificationClearingWorker.perform_with_capacity(...)
      end
    end
  end
end
