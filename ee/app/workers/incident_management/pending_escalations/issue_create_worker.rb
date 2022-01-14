# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class IssueCreateWorker
      include ApplicationWorker

      data_consistency :always
      worker_resource_boundary :cpu

      urgency :high

      idempotent!
      feature_category :incident_management

      def perform(issue_id)
        issue = ::Issue.find_by_id(issue_id)
        return unless issue

        escalation_status = issue.escalation_status
        return unless escalation_status

        ::IncidentManagement::PendingEscalations::CreateService.new(escalation_status).execute
      end
    end
  end
end
