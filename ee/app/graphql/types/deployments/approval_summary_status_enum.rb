# frozen_string_literal: true

module Types
  module Deployments
    class ApprovalSummaryStatusEnum < BaseEnum
      graphql_name 'DeploymentApprovalSummaryStatus'
      description 'Status of the deployment approval summary.'

      ::Deployments::ApprovalSummary::ALL_STATUSES.each do |status|
        value status.upcase,
              description: "Summarized deployment approval status that is #{status.tr('_', ' ')}.",
              value: status
      end
    end
  end
end
