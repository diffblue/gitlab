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
    end
  end
end
