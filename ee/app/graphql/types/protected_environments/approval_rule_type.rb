# frozen_string_literal: true

module Types
  module ProtectedEnvironments
    # This type is authorized in the parent entity.
    # rubocop:disable Graphql/AuthorizeTypes
    class ApprovalRuleType < AuthorizableType
      graphql_name 'ProtectedEnvironmentApprovalRule'
      description 'Which group, user or role is allowed to approve deployments to the environment.'

      field :required_approvals, GraphQL::Types::Int,
            description: "Number of required approvals."
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
