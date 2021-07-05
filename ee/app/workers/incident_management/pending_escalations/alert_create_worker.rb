# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class AlertCreateWorker
      include ApplicationWorker

      data_consistency :always

      urgency :high

      idempotent!
      feature_category :incident_management

      def perform(alert_id)
        alert = ::AlertManagement::Alert.find(alert_id)

        ::IncidentManagement::PendingEscalations::CreateService.new(alert).execute
      end
    end
  end
end
