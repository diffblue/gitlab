# frozen_string_literal: true

module EE
  module Issues
    module ReopenService
      extend ::Gitlab::Utils::Override

      override :perform_incident_management_actions
      def perform_incident_management_actions(issue)
        super
        update_issuable_sla(issue)
      end

      override :perform_reopen
      def perform_reopen(issue)
        sync_requirement_state(issue, 'opened') do
          super
        end
      end
    end
  end
end
