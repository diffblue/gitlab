# frozen_string_literal: true

module AppSec
  module Dast
    module Scans
      class AssociateService < BaseService
        def execute(pipeline:, dast_profile:)
          return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

          # skip_duplicates: true means this method inserts in an idempotent manner
          ::Dast::ProfilesPipeline.bulk_insert!(
            [::Dast::ProfilesPipeline.new(ci_pipeline_id: pipeline.id, dast_profile_id: dast_profile.id)],
            skip_duplicates: true
          )

          ServiceResponse.success
        end

        private

        def allowed?
          Ability.allowed?(current_user, :create_on_demand_dast_scan, project)
        end
      end
    end
  end
end
