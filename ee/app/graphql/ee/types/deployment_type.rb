# frozen_string_literal: true

module EE
  module Types
    module DeploymentType
      extend ActiveSupport::Concern

      prepended do
        field :pending_approval_count,
               GraphQL::Types::Int,
               description: 'Number of pending unified approvals on the deployment.' do
          extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
        end

        field :approval_summary,
              ::Types::Deployments::ApprovalSummaryType,
              description: 'Approval summary of the deployment.' \
                           'This field can only be resolved for one deployment in any single request.' do
          extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
        end

        field :approvals,
              type: [::Types::Deployments::ApprovalType],
              description: 'Current approvals of the deployment.' do
          extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
        end
      end
    end
  end
end
