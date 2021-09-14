# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module EscalationPolicy
      class Destroy < Base
        graphql_name 'EscalationPolicyDestroy'

        argument :id, Types::GlobalIDType[::IncidentManagement::EscalationPolicy],
                 required: true,
                 description: 'Escalation policy internal ID to remove.'

        def resolve(id:)
          escalation_policy = authorized_find!(id: id)

          response ::IncidentManagement::EscalationPolicies::DestroyService.new(
            escalation_policy,
            current_user
          ).execute
        end
      end
    end
  end
end
