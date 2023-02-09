# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class BackfillNotificationJobsWorker
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
        OverLimitNotificationWorker.perform_with_capacity(...)
      end
    end
  end
end
