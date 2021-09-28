# frozen_string_literal: true

module AppSec
  module Dast
    module Scans
      class CreateService < BaseContainerService
        def execute
          return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

          create_pipeline
        rescue KeyError => err
          ServiceResponse.error(message: err.message.capitalize)
        end

        private

        def allowed?
          container.licensed_feature_available?(:security_on_demand_scans)
        end

        def success_response(pipeline)
          pipeline_url = Rails.application.routes.url_helpers.project_pipeline_url(
            container,
            pipeline
          )

          ServiceResponse.success(
            payload: {
              pipeline: pipeline,
              pipeline_url: pipeline_url
            }
          )
        end

        def create_pipeline
          config_result = AppSec::Dast::ScanConfigs::BuildService.new(container: container, current_user: current_user, params: params).execute

          return config_result unless config_result.success?

          result = ::AppSec::Dast::Scans::RunService.new(container, current_user).execute(**config_result.payload)

          return success_response(result.payload) if result.success?

          result
        end
      end
    end
  end
end
