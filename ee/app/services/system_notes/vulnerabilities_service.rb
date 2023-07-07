# frozen_string_literal: true

module SystemNotes
  class VulnerabilitiesService < ::SystemNotes::BaseService
    # Called when state is changed for 'vulnerability'
    # Message is established based on the logic relating to the
    # vulnerability state enum and the current state.
    # If no state transition is present, we assume the vulnerability
    # is newly detected.
    def change_vulnerability_state(body = nil)
      body ||= state_change_body

      create_note(NoteSummary.new(noteable, project, author, body, action: "vulnerability_#{to_state}"))
    end

    class << self
      def formatted_note(from_state, to_state, dismissal_reason, comment)
        format(
          "%{from_state} vulnerability status to %{to_state}%{reason}%{comment}",
          from_state: from_state,
          to_state: to_state.to_s.titleize,
          comment: formatted_comment(comment),
          reason: formatted_reason(dismissal_reason, to_state)
        )
      end

      private

      def formatted_reason(dismissal_reason, to_state)
        return if to_state.to_sym != :dismissed
        return if dismissal_reason.blank?

        ": #{dismissal_reason.titleize}"
      end

      def formatted_comment(comment)
        return unless comment.present?

        format(' and the following comment: "%{comment}"', comment: comment)
      end
    end

    private

    def state_change_body
      if state_transition.present?
        self.class.formatted_note(
          from_status,
          to_state,
          state_transition.dismissal_reason,
          state_transition.comment
        )
      else
        "changed vulnerability status to Detected"
      end
    end

    def from_status
      state_transition.to_state_detected? ? 'reverted' : 'changed'
    end

    def to_state
      @to_state ||= state_transition&.to_state || 'detected'
    end

    def state_transition
      @state_transition ||= noteable.latest_state_transition
    end
  end
end
