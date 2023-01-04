# frozen_string_literal: true

module AppSec
  module Dast
    module ScannerProfiles
      class DestroyService < ::BaseService
        include Gitlab::Allowable

        def execute(id:)
          return unauthorized unless can_delete_scanner_profile?

          dast_scanner_profile = find_dast_scanner_profile(id)
          return ServiceResponse.error(message: _('Scanner profile not found for given parameters')) unless dast_scanner_profile
          return ServiceResponse.error(message: _('Cannot delete %{profile_name} referenced in security policy') % { profile_name: dast_scanner_profile.name }) if referenced_in_security_policy?(dast_scanner_profile)

          if dast_scanner_profile.destroy
            create_audit_event(dast_scanner_profile)

            ServiceResponse.success(payload: dast_scanner_profile)
          else
            ServiceResponse.error(message: _('Scanner profile failed to delete'))
          end
        end

        private

        def unauthorized
          ::ServiceResponse.error(message: _('You are not authorized to update this scanner profile'), http_status: 403)
        end

        def referenced_in_security_policy?(profile)
          profile.referenced_in_security_policies.present?
        end

        def can_delete_scanner_profile?
          can?(current_user, :create_on_demand_dast_scan, project)
        end

        def find_dast_scanner_profile(id)
          project.dast_scanner_profiles.id_in(id).first
        end

        def create_audit_event(profile)
          ::Gitlab::Audit::Auditor.audit(
            name: 'dast_scanner_profile_destroy',
            author: current_user,
            scope: project,
            target: profile,
            message: "Removed DAST scanner profile"
          )
        end
      end
    end
  end
end
