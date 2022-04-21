# frozen_string_literal: true

module EE
  module IncidentManagement
    module IssuableEscalationStatuses
      module BuildService
        extend ::Gitlab::Utils::Override

        override :alert_params
        def alert_params
          return super unless issue.escalation_policies_available?
          return super unless alert&.escalation_policy

          super.merge(
            policy: alert.escalation_policy,
            escalations_started_at: alert.created_at
          )
        end
      end
    end
  end
end
