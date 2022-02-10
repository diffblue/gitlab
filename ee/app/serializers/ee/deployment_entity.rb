# frozen_string_literal: true

module EE
  module DeploymentEntity
    extend ActiveSupport::Concern

    prepended do
      expose :pending_approval_count
      expose :approvals, using: ::API::Entities::Deployments::Approval

      expose :can_approve_deployment do |deployment|
        can?(request.current_user, :update_deployment, deployment)
      end
    end
  end
end
