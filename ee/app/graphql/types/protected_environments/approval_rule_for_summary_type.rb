# frozen_string_literal: true

module Types
  module ProtectedEnvironments
    # This type is authorized in the parent entity.
    # rubocop:disable Graphql/AuthorizeTypes
    class ApprovalRuleForSummaryType < ApprovalRuleType
      graphql_name 'ProtectedEnvironmentApprovalRuleForSummary'
      description 'Which group, user or role is allowed to approve deployments to the environment.'

      field :approved_count,
            type: GraphQL::Types::Int,
            description: 'Approved count.'

      field :pending_approval_count,
            type: GraphQL::Types::Int,
            description: 'Pending approval count.'

      field :status,
            Types::Deployments::ApprovalSummaryStatusEnum,
            description: 'Status of the approval summary.'

      field :approvals,
            type: [::Types::Deployments::ApprovalType],
            description: 'Current approvals of the deployment.',
            method: :approvals_for_summary
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
