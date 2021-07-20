# frozen_string_literal: true

module Ci
  class RunDastScanService < BaseService
    def execute(branch:, ci_configuration:, dast_profile: nil, dast_site_profile: nil, dast_scanner_profile: nil)
      return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

      service = Ci::CreatePipelineService.new(project, current_user, ref: branch)

      response = service.execute(:ondemand_dast_scan, content: ci_configuration) do |pipeline|
        if dast_profile
          pipeline.dast_profile = dast_profile
        else
          # Subject to change. Please see gitlab-org/gitlab#330950 for more info.
          pipeline.dast_site_profile = dast_site_profile
        end
      end

      pipeline = response.payload
      if pipeline.created_successfully?
        ServiceResponse.success(payload: pipeline)
      else
        ServiceResponse.error(message: pipeline.full_error_messages)
      end
    end

    private

    def allowed?
      Ability.allowed?(current_user, :create_on_demand_dast_scan, project)
    end
  end
end
