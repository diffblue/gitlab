# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module EscalationPolicy
      class Create < Base
        graphql_name 'EscalationPolicyCreate'

        include ResolvesProject

        argument :project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Project to create the escalation policy for.'

        argument :name, GraphQL::Types::String,
                 required: true,
                 description: 'Name of the escalation policy.'

        argument :description, GraphQL::Types::String,
                 required: false,
                 description: 'Description of the escalation policy.'

        argument :rules, [Types::IncidentManagement::EscalationRuleInputType],
                 required: true,
                 description: 'Steps of the escalation policy.'

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
