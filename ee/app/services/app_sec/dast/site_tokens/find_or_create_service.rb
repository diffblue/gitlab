# frozen_string_literal: true

module AppSec
  module Dast
    module SiteTokens
      class FindOrCreateService < BaseProjectService
        def execute
          return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

          existing_validation = find_dast_site_validation

          return success_response(existing_validation.dast_site_token, existing_validation.state) if existing_validation

          find_or_create_dast_site_token
        rescue Addressable::URI::InvalidURIError
          error_response('Invalid target_url')
        end

        private

        def allowed?
          project.licensed_feature_available?(:security_on_demand_scans)
        end

        def error_response(message)
          ServiceResponse.error(message: message)
        end

        def success_response(dast_site_token, status)
          ServiceResponse.success(payload: { dast_site_token: dast_site_token, status: status })
        end

        def find_or_create_dast_site_token
          existing_token = DastSiteToken.find_by(project: project, url: params[:target_url]) # rubocop: disable CodeReuse/ActiveRecord

          return success_response(existing_token, DastSiteValidation::INITIAL_STATE) if existing_token

          new_token = DastSiteToken.create(project: project, token: SecureRandom.uuid, url: params[:target_url])

          return error_response(new_token.errors.full_messages) unless new_token.valid?

          success_response(new_token, DastSiteValidation::INITIAL_STATE)
        end

        def find_dast_site_validation
          url_base = DastSiteValidation.get_normalized_url_base(params[:target_url])

          DastSiteValidationsFinder.new(project_id: project.id, url_base: url_base)
            .execute
            .first
        end
      end
    end
  end
end
