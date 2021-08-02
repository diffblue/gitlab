# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class AlertCreateWorker
      include ApplicationWorker

      data_consistency :always
      worker_resource_boundary :cpu

      urgency :high

      idempotent!
      feature_category :incident_management

      def perform(alert_id)
        alert = ::AlertManagement::Alert.find_by_id(alert_id)
        return unless alert

        ::IncidentManagement::PendingEscalations::CreateService.new(alert).execute
      end
    end
  end
end
