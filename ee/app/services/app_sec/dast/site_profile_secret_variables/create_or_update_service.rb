# frozen_string_literal: true

module AppSec
  module Dast
    module SiteProfileSecretVariables
      class CreateOrUpdateService < BaseContainerService
        def execute
          return error_response('Insufficient permissions') unless allowed?

          return error_response('Dast site profile param is missing') unless site_profile
          return error_response('Key param is missing') unless key
          return error_response('Raw value param is missing') unless raw_value

          secret_variable = find_or_create_secret_variable

          return error_response(secret_variable.errors.full_messages) unless secret_variable.valid? && secret_variable.persisted?

          success_response(secret_variable)
        end

        private

        def allowed?
          Ability.allowed?(current_user, :create_on_demand_dast_scan, container)
        end

        def site_profile
          params[:dast_site_profile]
        end

        def key
          params[:key]
        end

        def raw_value
          params[:raw_value]
        end

        def success_response(secret_variable)
          ServiceResponse.success(payload: secret_variable)
        end

        def error_response(message)
          ServiceResponse.error(message: message)
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find_or_create_secret_variable
          secret_variable = ::Dast::SiteProfileSecretVariable.find_or_initialize_by(dast_site_profile: site_profile, key: key)
          secret_variable.update(raw_value: raw_value)

          secret_variable
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
