# frozen_string_literal: true

module EE
  module API
    module Entities
      module DeploymentExtended
        extend ActiveSupport::Concern

        prepended do
          expose :pending_approval_count, documentation: { type: 'integer', example: 0 }
          expose :approvals, using: ::API::Entities::Deployments::Approval
          expose :approval_summary, using: ::API::Entities::Deployments::ApprovalSummary
        end
      end
    end
  end
end
