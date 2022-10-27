# frozen_string_literal: true

module Types
  module Deployments
    # This type is authorized in the parent entity.
    # rubocop:disable Graphql/AuthorizeTypes
    class ApprovalSummaryType < BaseObject
      graphql_name 'DeploymentApprovalSummary'
      description 'Approval summary of the deployment.'

      field :total_required_approvals,
            GraphQL::Types::Int,
            description: 'Total number of required approvals.'

      field :total_pending_approval_count,
            GraphQL::Types::Int,
            description: 'Total pending approval count.'

      field :status,
            Types::Deployments::ApprovalSummaryStatusEnum,
            description: 'Status of the approvals.'

      field :rules,
            [ProtectedEnvironments::ApprovalRuleForSummaryType],
            description: 'Approval Rules for the deployment.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
