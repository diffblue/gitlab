# frozen_string_literal: true

module EE
  module Types
    module DeploymentType
      extend ActiveSupport::Concern

      prepended do
        field :approval_summary,
              ::Types::Deployments::ApprovalSummaryType,
              description: 'Approval summary of the deployment.' \
                           'This field can only be resolved for one deployment in any single request.' do
          extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
        end
      end
    end
  end
end
