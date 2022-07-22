# frozen_string_literal: true

module AppSec
  module Dast
    module Pipelines
      class FindLatestService < BaseProjectService
        include ::Security::LatestPipelineInformation
        include Gitlab::Utils::StrongMemoize

        def execute
          return ServiceResponse.error(message: _('Insufficient permissions')) unless allowed?

          payload = {}

          if scanner_enabled?(:dast)
            payload[:latest_pipeline] = latest_pipeline
          end

          ServiceResponse.success(
            payload: payload
          )
        end

        private

        def allowed?
          Ability.allowed?(current_user, :read_on_demand_dast_scan, project)
        end

        def latest_pipeline
          strong_memoize(:latest_pipeline) { @project.latest_pipeline }
        end
      end
    end
  end
end
