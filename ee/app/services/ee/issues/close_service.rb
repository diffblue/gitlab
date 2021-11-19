# frozen_string_literal: true

module EE
  module Issues
    module CloseService
      extend ::Gitlab::Utils::Override

      override :perform_incident_management_actions
      def perform_incident_management_actions(issue)
        super
        update_issuable_sla(issue)
      end

      override :perform_close
      def perform_close(issue)
        sync_requirement_state(issue, 'archived') do
          super
        end
      end

      override :create_note
      def create_note(issue, current_commit)
        state = issue.requirement? ? 'closed' : issue.state
        ::SystemNoteService.change_status(issue, issue.project, current_user, state, current_commit)
      end
    end
  end
end
