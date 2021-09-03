# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module EscalationPolicy
      class Update < Base
        graphql_name 'EscalationPolicyUpdate'

        argument :id, ::Types::GlobalIDType[::IncidentManagement::EscalationPolicy],
                 required: true,
                 description: 'ID of the on-call schedule to create the on-call rotation in.'

        argument :name, GraphQL::Types::String,
                 required: false,
                 description: 'Name of the escalation policy.'

        argument :description, GraphQL::Types::String,
                 required: false,
                 description: 'Description of the escalation policy.'

        argument :rules, [Types::IncidentManagement::EscalationRuleInputType],
                 required: false,
                 description: 'Steps of the escalation policy.'

        def resolve(id:, **args)
          policy = authorized_find!(id: id)
          args = prepare_rules_attributes(policy.project, args)

          response ::IncidentManagement::EscalationPolicies::UpdateService.new(
            policy,
            current_user,
            args
          ).execute
        end
      end
    end
  end
end
