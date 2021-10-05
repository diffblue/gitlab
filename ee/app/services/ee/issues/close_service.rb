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
    end
  end
end
