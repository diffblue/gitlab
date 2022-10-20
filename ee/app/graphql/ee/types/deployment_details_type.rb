# frozen_string_literal: true

module EE
  module Types
    module DeploymentDetailsType
      extend ActiveSupport::Concern

      prepended do
        field :approval_summary,
              ::Types::Deployments::ApprovalSummaryType,
              description: 'Approval summary of the deployment.'
      end
    end
  end
end
