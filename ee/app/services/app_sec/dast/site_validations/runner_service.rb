# frozen_string_literal: true

module AppSec
  module Dast
    module SiteValidations
      class RunnerService < BaseProjectService
        def execute
          return ServiceResponse.error(message: _('Insufficient permissions')) unless allowed?

          service = Ci::CreatePipelineService.new(project, current_user, ref: project.default_branch_or_main)
          result = service.execute(:ondemand_dast_validation, content: ci_configuration.to_yaml, variables_attributes: dast_site_validation_variables)

          if result.success?
            ServiceResponse.success(payload: dast_site_validation)
          else
            dast_site_validation.fail_op

            result
          end
        end

        private

        def allowed?
          can?(current_user, :create_on_demand_dast_scan, project)
        end

        def dast_site_validation
          @dast_site_validation ||= params[:dast_site_validation]
        end

        def ci_configuration
          { 'include' => [{ 'template' => 'Security/DAST-Runner-Validation.gitlab-ci.yml' }] }
        end

        def dast_site_validation_variables
          [
            { key: 'DAST_SITE_VALIDATION_ID', secret_value: String(dast_site_validation.id) },
            { key: 'DAST_SITE_VALIDATION_HEADER', secret_value: ::DastSiteValidation::HEADER },
            { key: 'DAST_SITE_VALIDATION_STRATEGY', secret_value: dast_site_validation.validation_strategy },
            { key: 'DAST_SITE_VALIDATION_TOKEN', secret_value: dast_site_validation.dast_site_token.token },
            { key: 'DAST_SITE_VALIDATION_URL', secret_value: dast_site_validation.validation_url }
          ]
        end
      end
    end
  end
end
