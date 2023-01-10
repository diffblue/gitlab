# frozen_string_literal: true

module SystemNotes
  class VulnerabilitiesService < ::SystemNotes::BaseService
    # Called when state is changed for 'vulnerability'
    def change_vulnerability_state(body = nil)
      body ||= format(
        "%{from_status} vulnerability status to %{to_status}",
        from_status: noteable.detected? ? 'reverted' : 'changed',
        to_status: noteable.state
      )

      create_note(NoteSummary.new(noteable, project, author, body, action: "vulnerability_#{noteable.state}"))
    end
  end
end
