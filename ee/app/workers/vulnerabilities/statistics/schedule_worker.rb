# frozen_string_literal: true

module Vulnerabilities
  module Statistics
    class ScheduleWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      feature_category :vulnerability_management

      BATCH_SIZE = 500
      DELAY_INTERVAL = 30.seconds.to_i

      # rubocop: disable CodeReuse/ActiveRecord
      def perform
        ProjectSetting.has_vulnerabilities.each_batch(of: BATCH_SIZE) do |relation, index|
          project_ids = relation.left_outer_joins(:project).merge(::Project.without_deleted).pluck(:project_id)
          AdjustmentWorker.perform_in(index * DELAY_INTERVAL, project_ids)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
