# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class IssueCheckWorker
      include ApplicationWorker

      data_consistency :always
      worker_resource_boundary :cpu

      urgency :high

      idempotent!
      feature_category :incident_management

      def perform(escalation_id)
        escalation = IncidentManagement::PendingEscalations::Issue.find_by_id(escalation_id)
        return unless escalation

        IncidentManagement::PendingEscalations::ProcessService.new(escalation).execute
      end
    end
  end
end
