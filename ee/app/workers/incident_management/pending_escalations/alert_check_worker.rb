# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class AlertCheckWorker
      include ApplicationWorker

      data_consistency :always

      urgency :high

      idempotent!
      feature_category :incident_management

      def perform(escalation_id)
        escalation = IncidentManagement::PendingEscalations::Alert.find(escalation_id)

        IncidentManagement::PendingEscalations::ProcessService.new(escalation).execute
      end
    end
  end
end
