# frozen_string_literal: true

module AppSec
  module Dast
    module ScannerProfiles
      class CreateService < BaseService
        def execute
          return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

          dast_scanner_profile = DastScannerProfile.create(create_params)

          if dast_scanner_profile.valid?
            create_audit_event(dast_scanner_profile)

            ServiceResponse.success(payload: dast_scanner_profile)
          else
            ServiceResponse.error(message: dast_scanner_profile.errors.full_messages)
          end
        end

        private

        def allowed?
          Ability.allowed?(current_user, :create_on_demand_dast_scan, project)
        end

        def create_audit_event(profile)
          ::Gitlab::Audit::Auditor.audit(
            name: 'dast_scanner_profile_create',
            author: current_user,
            scope: project,
            target: profile,
            message: "Added DAST scanner profile"
          )
        end

        def create_params
          base_params.merge({ name: params[:name], project: project })
        end
      end
    end
  end
end
