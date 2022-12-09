# frozen_string_literal: true

module EE
  module EnvironmentsHelper
    extend ::Gitlab::Utils::Override

    def deployment_approval_data(deployment)
      { pending_approval_count: deployment.pending_approval_count,
        iid: deployment.iid,
        id: deployment.id,
        required_approval_count: deployment.environment.required_approval_count,
        can_approve_deployment: can_approve_deployment?(deployment).to_s,
        deployable_name: deployment.deployable&.name,
        has_approval_rules: deployment.environment.has_approval_rules?.to_s,
        approvals: ::API::Entities::Deployments::Approval.represent(deployment.approvals).to_json,
        project_id: deployment.project_id,
        project_path: deployment.project.full_path,
        name: deployment.environment.name,
        tier: deployment.environment.tier }
    end

    def show_deployment_approval?(deployment)
      can?(current_user, :read_deployment, deployment)
    end

    def can_approve_deployment?(deployment)
      can?(current_user, :approve_deployment, deployment)
    end
  end
end
