# frozen_string_literal: true

module Iterations
  module Cadences
    class ScheduleCreateIterationsWorker
      include ApplicationWorker

      data_consistency :always

      BATCH_SIZE = 1000

      idempotent!
      deduplicate :until_executed, including_scheduled: true

      queue_namespace :cronjob
      feature_category :team_planning

      def perform
        Iterations::Cadence.next_to_auto_schedule.each_batch(of: BATCH_SIZE) do |cadences|
          cadences.each do |cadence|
            Iterations::Cadences::CreateIterationsWorker.perform_async(cadence.id)
          end
        end
      end
    end
  end
end
