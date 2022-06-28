# frozen_string_literal: true

module EE
  module EnvironmentsHelper
    extend ::Gitlab::Utils::Override

    override :project_metrics_data
    def project_metrics_data(project)
      super
    end

    override :project_and_environment_metrics_data
    def project_and_environment_metrics_data(project, environment)
      super
    end

    def deployment_approval_data(deployment)
      { pending_approval_count: deployment.pending_approval_count,
        iid: deployment.iid,
        id: deployment.id,
        required_approval_count: deployment.environment.required_approval_count,
        can_approve_deployment: can?(current_user, :update_deployment, deployment).to_s,
        deployable_name: deployment.deployable&.name,
        approvals: ::API::Entities::Deployments::Approval.represent(deployment.approvals).to_json,
        project_id: deployment.project_id,
        name: deployment.environment.name,
        tier: deployment.environment.tier }
    end

    def show_deployment_approval?(deployment)
      can?(current_user, :update_deployment, deployment) &&
        deployment.environment.required_approval_count > 0
    end
  end
end
