# frozen_string_literal: true

module Security
  class ApplicationController < ::ApplicationController
    include SecurityDashboardsPermissions

    before_action do
      push_frontend_feature_flag(:vulnerability_management_survey, type: :ops, default_enabled: :yaml)
    end

    feature_category :vulnerability_management

    protected

    def vulnerable
      @vulnerable ||= InstanceSecurityDashboard.new(
        current_user,
        project_ids: params.fetch(:project_id, [])
      )
    end
  end
end
