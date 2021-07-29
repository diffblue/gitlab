# frozen_string_literal: true

module SystemNotes
  class EscalationsService < ::SystemNotes::BaseService
    def initialize(noteable: nil, project: nil)
      @noteable = noteable
      @project = project
      @author = User.alert_bot
    end

    def notify_via_escalation(recipients, escalation_policy:)
      body = "notified #{recipients.map(&:to_reference).to_sentence} of this alert via escalation policy **#{escalation_policy.name}**"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'new_alert_added'))
    end
  end
end
