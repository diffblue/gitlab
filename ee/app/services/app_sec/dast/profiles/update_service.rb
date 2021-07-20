# frozen_string_literal: true

module AppSec
  module Dast
    module Profiles
      class UpdateService < BaseContainerService
        include Gitlab::Utils::StrongMemoize

        def execute
          return unauthorized unless allowed?
          return error('Profile parameter missing') unless dast_profile

          auditor = AppSec::Dast::Profiles::Audit::UpdateService.new(container: container, current_user: current_user, params: {
            dast_profile: dast_profile,
            new_params: dast_profile_params,
            old_params: dast_profile.attributes.symbolize_keys
          })

          return error(dast_profile.errors.full_messages) unless dast_profile.update(dast_profile_params)

          auditor.execute

          return success(dast_profile: dast_profile, pipeline_url: nil) unless params[:run_after_update]

          response = create_scan(dast_profile)

          return error(response.message) if response.error?

          success(dast_profile: dast_profile, pipeline_url: response.payload.fetch(:pipeline_url))
        end

        private

        def allowed?
          container.licensed_feature_available?(:security_on_demand_scans) &&
            can?(current_user, :create_on_demand_dast_scan, container)
        end

        def error(message, opts = {})
          ServiceResponse.error(message: message, **opts)
        end

        def success(payload)
          ServiceResponse.success(payload: payload)
        end

        def unauthorized
          error('You are not authorized to update this profile', http_status: 403)
        end

        def dast_profile
          params[:dast_profile]
        end

        def dast_profile_params
          params.slice(:dast_site_profile_id, :dast_scanner_profile_id, :name, :description, :branch_name)
        end

        def create_scan(dast_profile)
          ::DastOnDemandScans::CreateService.new(
            container: container,
            current_user: current_user,
            params: { dast_profile: dast_profile }
          ).execute
        end
      end
    end
  end
end
