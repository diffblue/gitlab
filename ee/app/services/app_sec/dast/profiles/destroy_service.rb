# frozen_string_literal: true

module AppSec
  module Dast
    module Profiles
      class DestroyService < BaseContainerService
        def execute
          return unauthorized unless allowed?
          return ServiceResponse.error(message: _('Profile parameter missing')) unless dast_profile
          return ServiceResponse.error(message: _('Profile failed to delete')) unless dast_profile.destroy

          create_audit_event

          ServiceResponse.success(payload: dast_profile)
        end

        private

        def allowed?
          can?(current_user, :create_on_demand_dast_scan, container)
        end

        def unauthorized
          ServiceResponse.error(
            message: _('You are not authorized to update this profile'),
            http_status: 403
          )
        end

        def dast_profile
          params[:dast_profile]
        end

        def create_audit_event
          ::Gitlab::Audit::Auditor.audit(
            name: 'dast_profile_destroy',
            author: current_user,
            scope: container,
            target: dast_profile,
            message: 'Removed DAST profile'
          )
        end
      end
    end
  end
end
