# frozen_string_literal: true

module Security
  class VulnerabilitiesController < ::Security::ApplicationController
    layout 'instance_security'
    include GovernUsageTracking

    before_action do
      push_frontend_feature_flag(:expose_dismissal_reason, @project)
    end

    track_govern_activity 'security_vulnerabilities', :index

    private

    def tracking_namespace_source
      nil
    end

    def tracking_project_source
      nil
    end
  end
end
