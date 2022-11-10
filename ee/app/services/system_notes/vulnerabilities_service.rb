# frozen_string_literal: true

module SystemNotes
  class VulnerabilitiesService < ::SystemNotes::BaseService
    # Called when state is changed for 'vulnerability'
    def change_vulnerability_state
      type = noteable.detected? ? 'reverted' : 'changed'
      body = "#{type} vulnerability status to #{noteable.state}"

      create_note(NoteSummary.new(noteable, project, author, body, action: "vulnerability_#{noteable.state}"))
    end

    def mark_dropped_as_resolved(body)
      create_note(NoteSummary.new(noteable, project, author, body, action: "vulnerability_#{noteable.state}"))
    end
  end
end
