# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module EscalationPolicy
      class Create < Base
        include ResolvesProject

        graphql_name 'EscalationPolicyCreate'

        argument :project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'The project to create the escalation policy for.'

        argument :name, GraphQL::Types::String,
                 required: true,
                 description: 'The name of the escalation policy.'

        argument :description, GraphQL::Types::String,
                 required: false,
                 description: 'The description of the escalation policy.'

        argument :rules, [Types::IncidentManagement::EscalationRuleInputType],
                 required: true,
                 description: 'The steps of the escalation policy.'

        def resolve(project_path:, **args)
          project = authorized_find!(project_path: project_path, **args)
          args = prepare_rules_attributes(project, args)

          result = ::IncidentManagement::EscalationPolicies::CreateService.new(
            project,
            current_user,
            args
          ).execute

          response(result)
        end

        private

        def find_object(project_path:, **args)
          resolve_project(full_path: project_path).sync
        end

        def escalation_policies_available?(project)
          ::Gitlab::IncidentManagement.escalation_policies_available?(project)
        end
      end
    end
  end
end
