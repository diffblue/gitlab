# frozen_string_literal: true

module Types
  # This type is authorized in the parent entity.
  # rubocop: disable Graphql/AuthorizeTypes
  class ProtectedEnvironmentType < BaseObject
    graphql_name 'ProtectedEnvironment'
    description 'Protected Environments of the environment.'

    field :name, GraphQL::Types::String,
          description: "Name of the environment if it's a project-level protected environment. " \
                       "Tier of the environment if it's a group-level protected environment."

    field :project, ::Types::ProjectType,
          description: "Project details. Present if it's project-level protected environment."

    field :group, '::Types::GroupType',
          description: "Group details. Present if it's group-level protected environment."

    field :deploy_access_levels, ::Types::ProtectedEnvironments::DeployAccessLevelType.connection_type,
          description: 'Which group, user or role is allowed to execute deployments to the environment.'

    field :approval_rules, ::Types::ProtectedEnvironments::ApprovalRuleType.connection_type,
          description: 'Which group, user or role is allowed to approve deployments to the environment.'

    field :required_approval_count, GraphQL::Types::Int,
          description: "Required approval count for Unified Approval Setting."
  end
  # rubocop:enable Graphql/AuthorizeTypes
end
