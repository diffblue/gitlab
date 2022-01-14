# frozen_string_literal: true

module SystemNotes
  class EscalationsService < ::SystemNotes::BaseService
    def initialize(noteable: nil, project: nil)
      @noteable = noteable
      @project = project
      @author = User.alert_bot
    end

    def notify_via_escalation(recipients, escalation_policy:, type:)
      body = "notified #{recipients.map(&:to_reference).to_sentence} of this #{type} via escalation policy **#{escalation_policy.name}**"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'new_alert_added'))
    end

    def start_escalation(escalation_policy, author)
      path = url_helpers.project_incident_management_escalation_policies_path(project)
      body = "paged escalation policy [#{escalation_policy.name}](#{path})"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'paging_started'))
    end
  end
end
