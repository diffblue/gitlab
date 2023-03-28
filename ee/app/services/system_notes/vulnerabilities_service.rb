# frozen_string_literal: true

module SystemNotes
  class VulnerabilitiesService < ::SystemNotes::BaseService
    # Called when state is changed for 'vulnerability'
    # Message is established based on the logic relating to the
    # vulnerability state enum and the current state.
    # If no state transition is present, we assume the vulnerability
    # is newly detected.
    def change_vulnerability_state(body = nil)
      @state_transition = noteable.latest_state_transition

      body ||= state_change_body

      create_note(NoteSummary.new(noteable, project, author, body, action: "vulnerability_#{to_state}"))
    end

    private

    def to_state
      @to_state ||= @state_transition&.to_state || 'detected'
    end

    def state_change_body
      if @state_transition.present?
        format(
          "%{from_status} vulnerability status to %{to_status}%{dismissal_reason}",
          from_status: @state_transition.to_state_detected? ? 'reverted' : 'changed',
          to_status: to_state.titleize,
          dismissal_reason: dismissal_reason
        )
      else
        "changed vulnerability status to Detected"
      end
    end

    def dismissal_reason
      return unless @state_transition.to_state_dismissed? && @state_transition.dismissal_reason.present?

      ": #{@state_transition.dismissal_reason.titleize}"
    end
  end
end
