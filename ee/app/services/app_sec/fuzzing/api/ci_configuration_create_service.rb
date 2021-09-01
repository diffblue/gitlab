# frozen_string_literal: true

module AppSec
  module Fuzzing
    module API
      class CiConfigurationCreateService < ::BaseContainerService
        API_SPECIFICATION_CI_VARIABLES = {
          har: 'FUZZAPI_HAR',
          openapi: 'FUZZAPI_OPENAPI',
          postman: 'FUZZAPI_POSTMAN_COLLECTION'
        }.freeze

        def create
          success(yaml: preset_configuration.merge({ 'variables' => variables }))
        end

        private

        def preset_configuration
          {
            'stages' => ['fuzz'],
            'include' => [{ 'template' => 'Security/API-Fuzzing.gitlab-ci.yml' }]
          }
        end

        def variables
          { 'FUZZAPI_TARGET_URL' => params[:target] }
            .merge(api_specification_file)
            .merge(optional_variables)
        end

        def api_specification_file
          { API_SPECIFICATION_CI_VARIABLES[params[:scan_mode]] => params[:api_specification_file] }
        end

        def optional_variables
          optionals = {}

          if params[:auth_password]
            optionals['FUZZAPI_HTTP_PASSWORD'] = params[:auth_password]
          end

          if params[:auth_username]
            optionals['FUZZAPI_HTTP_USERNAME'] = params[:auth_username]
          end

          if params[:scan_profile]
            optionals['FUZZAPI_PROFILE'] = params[:scan_profile]
          end

          optionals
        end
      end
    end
  end
end
