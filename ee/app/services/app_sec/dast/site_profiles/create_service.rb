# frozen_string_literal: true

module AppSec
  module Dast
    module SiteProfiles
      class CreateService < BaseService
        class Rollback < StandardError
          attr_reader :errors

          def initialize(errors)
            @errors = errors
          end
        end

        attr_reader :dast_site, :dast_site_profile, :dast_site_validation

        def execute(name:, target_url:, **params)
          return ServiceResponse.error(message: _('Insufficient permissions')) unless allowed?

          ApplicationRecord.transaction do
            @dast_site = ::DastSites::FindOrCreateService.new(project, current_user).execute!(url: target_url)
            params.merge!(project: project, dast_site: dast_site, name: name).compact!

            @dast_site_validation = find_existing_dast_site_validation
            associate_dast_site_validation! if dast_site_validation

            @dast_site_profile = DastSiteProfile.create!(params.except(:request_headers, :auth_password))
            create_secret_variable!(::Dast::SiteProfileSecretVariable::PASSWORD, params[:auth_password])
            create_secret_variable!(::Dast::SiteProfileSecretVariable::REQUEST_HEADERS, params[:request_headers])

            create_audit_event

            ServiceResponse.success(payload: dast_site_profile)
          end
        rescue Rollback => e
          ServiceResponse.error(message: e.errors)
        rescue ActiveRecord::RecordInvalid => e
          ServiceResponse.error(message: e.record.errors.full_messages)
        end

        private

        def allowed?
          Ability.allowed?(current_user, :create_on_demand_dast_scan, project)
        end

        def associate_dast_site_validation!
          dast_site.update!(dast_site_validation_id: dast_site_validation.id)
        end

        def create_secret_variable!(key, value)
          return ServiceResponse.success unless value

          response = ::Dast::SiteProfileSecretVariables::CreateOrUpdateService.new(
            container: project,
            current_user: current_user,
            params: { dast_site_profile: dast_site_profile, key: key, raw_value: value }
          ).execute

          raise Rollback, response.errors if response.error?

          response
        end

        def find_existing_dast_site_validation
          url_base = DastSiteValidation.get_normalized_url_base(dast_site.url)

          DastSiteValidationsFinder.new(
            project_id: project.id,
            url_base: url_base
          ).execute.first
        end

        def create_audit_event
          ::Gitlab::Audit::Auditor.audit(
            name: 'dast_site_profile_create',
            author: current_user,
            scope: project,
            target: dast_site_profile,
            message: 'Added DAST site profile'
          )
        end
      end
    end
  end
end
