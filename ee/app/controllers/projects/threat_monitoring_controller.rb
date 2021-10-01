# frozen_string_literal: true

module Projects
  class ThreatMonitoringController < Projects::ApplicationController
    include SecurityAndCompliancePermissions

    before_action :authorize_read_threat_monitoring!

    feature_category :not_owned

    # rubocop: disable CodeReuse/ActiveRecord
    def alert_details
      @alert_iid = AlertManagement::AlertsFinder.new(current_user, project, params.merge(domain: 'threat_monitoring')).execute.first!.iid
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def edit
      redirect_to edit_project_security_policy_path(
        project,
        environment_id: params[:environment_id],
        id: params[:id],
        type: :container_policy,
        kind: params[:kind]
      )
    end

    def new
      redirect_to new_project_security_policy_path(project)
    end
  end
end
