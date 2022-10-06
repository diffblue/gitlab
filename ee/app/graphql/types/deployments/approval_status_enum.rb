# frozen_string_literal: true

module Types
  module Deployments
    class ApprovalStatusEnum < BaseEnum
      graphql_name 'DeploymentsApprovalStatus'
      description 'Status of the deployment approval.'

      ::Deployments::Approval.statuses.each_key do |status|
        value status.upcase,
              description: "A deployment approval that is #{status.tr('_', ' ')}.",
              value: status
      end
    end
  end
end
