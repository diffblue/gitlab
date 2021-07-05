# frozen_string_literal: true

module Vulnerabilities
  module Statistics
    class ScheduleWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      feature_category :vulnerability_management

      BATCH_SIZE = 500
      DELAY_INTERVAL = 30.seconds.to_i

      def perform
        Project.without_deleted.has_vulnerabilities.each_batch(of: BATCH_SIZE) do |relation, index|
          AdjustmentWorker.perform_in(index * DELAY_INTERVAL, relation.pluck(:id)) # rubocop: disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
