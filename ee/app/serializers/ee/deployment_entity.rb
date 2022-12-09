# frozen_string_literal: true

module EE
  module DeploymentEntity
    extend ActiveSupport::Concern

    prepended do
      expose :pending_approval_count
      expose :approvals, using: ::API::Entities::Deployments::Approval

      expose :can_approve_deployment do |deployment|
        can?(request.current_user, :approve_deployment, deployment)
      end

      expose :has_approval_rules do |deployment|
        deployment.environment.has_approval_rules?
      end
    end
  end
end
