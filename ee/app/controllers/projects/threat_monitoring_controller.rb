# frozen_string_literal: true

module Projects
  class ThreatMonitoringController < Projects::ApplicationController
    include SecurityAndCompliancePermissions

    before_action :authorize_read_threat_monitoring!

    before_action do
      push_frontend_feature_flag(:security_orchestration_policies_configuration, @project)
    end

    feature_category :not_owned

    # rubocop: disable CodeReuse/ActiveRecord
    def alert_details
      @alert_iid = AlertManagement::AlertsFinder.new(current_user, project, params.merge(domain: 'threat_monitoring')).execute.first!.iid
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def edit
      @environment = project.environments.find(params[:environment_id])
      @policy_name = params[:id]
      response = NetworkPolicies::FindResourceService.new(
        resource_name: @policy_name,
        environment: @environment,
        kind: params[:kind].presence || Gitlab::Kubernetes::CiliumNetworkPolicy::KIND
      ).execute

      if response.success?
        @policy = response.payload
      else
        render_404
      end
    end
  end
end
