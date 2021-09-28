# frozen_string_literal: true

module AppSec
  module Dast
    module SiteProfileSecretVariables
      class DestroyService < BaseContainerService
        def execute
          return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?
          return ServiceResponse.error(message: 'Variable parameter missing') unless dast_site_profile_secret_variable
          return ServiceResponse.error(message: 'Variable failed to delete') unless dast_site_profile_secret_variable.destroy

          ServiceResponse.success(payload: dast_site_profile_secret_variable)
        end

        private

        def allowed?
          Ability.allowed?(current_user, :create_on_demand_dast_scan, container)
        end

        def dast_site_profile_secret_variable
          params[:dast_site_profile_secret_variable]
        end
      end
    end
  end
end
