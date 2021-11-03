# frozen_string_literal: true

module IncidentManagement
  module OncallRotations
    class PersistAllRotationsShiftsJob
      include ApplicationWorker

      data_consistency :always
      worker_resource_boundary :cpu

      sidekiq_options retry: 3

      idempotent!
      feature_category :incident_management
      queue_namespace :cronjob

      def perform
        IncidentManagement::OncallRotation.each_batch do |rotations|
          rotations.in_progress.ids.each do |id| # rubocop: disable CodeReuse/ActiveRecord
            IncidentManagement::OncallRotations::PersistShiftsJob.perform_async(id)
          end
        end
      end
    end
  end
end
