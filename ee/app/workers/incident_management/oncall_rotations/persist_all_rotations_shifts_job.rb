# frozen_string_literal: true

module IncidentManagement
  module OncallRotations
    class PersistAllRotationsShiftsJob
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3

      idempotent!
      feature_category :incident_management
      tags :exclude_from_kubernetes
      queue_namespace :cronjob

      def perform
        IncidentManagement::OncallRotation.in_progress.pluck(:id).each do |rotation_id| # rubocop: disable CodeReuse/ActiveRecord
          IncidentManagement::OncallRotations::PersistShiftsJob.perform_async(rotation_id)
        end
      end
    end
  end
end
