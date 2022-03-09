# frozen_string_literal: true

module Deployments
  class ApprovalService < ::BaseService
    def execute(deployment, status)
      error_message = validate(deployment, status)
      return error(error_message) if error_message

      approval = upsert_approval(deployment, status, params[:comment])
      return error(approval.errors.full_messages) if approval.errors.any?

      process_build!(deployment, approval)

      success(approval: approval)
    end

    private

    def upsert_approval(deployment, status, comment)
      if (approval = deployment.approvals.find_by_user_id(current_user.id))
        return approval if approval.status == status

        approval.tap { |a| a.update(status: status, comment: comment) }
      else
        deployment.approvals.create(user: current_user, status: status, comment: comment)
      end
    end

    def process_build!(deployment, approval)
      return unless deployment.deployable

      if approval.rejected?
        deployment.deployable.drop!(:deployment_rejected)
      elsif deployment.pending_approval_count <= 0
        deployment.unblock!
        deployment.deployable.enqueue!
      end
    end

    def validate(deployment, status)
      return 'Unrecognized status' unless Deployments::Approval.statuses.include?(status)

      return 'This environment is not protected' unless deployment.environment.protected?

      return 'You do not have permission to approve or reject this deployment' unless current_user&.can?(:update_deployment, deployment)

      return 'This deployment job is not waiting for approvals' unless deployment.blocked?

      'The same user can not approve' if deployment.user == current_user && status == 'approved'
    end
  end
end
