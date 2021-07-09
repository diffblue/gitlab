# frozen_string_literal: true

module AppSec
  module Dast
    module SiteProfiles
      class UpdateService < BaseService
        class Rollback < StandardError
          attr_reader :errors

          def initialize(errors)
            @errors = errors
          end
        end

        attr_reader :dast_site_profile

        def execute(id:, **params)
          return ServiceResponse.error(message: _('Insufficient permissions')) unless allowed?

          find_dast_site_profile!(id)

          return ServiceResponse.error(message: _('Cannot modify %{profile_name} referenced in security policy') % { profile_name: dast_site_profile.name }) if referenced_in_security_policy?

          ApplicationRecord.transaction do
            auditor = AppSec::Dast::SiteProfiles::Audit::UpdateService.new(project, current_user, {
              dast_site_profile: dast_site_profile,
              new_params: params.dup,
              old_params: dast_site_profile.attributes.symbolize_keys.merge(
                target_url: dast_site_profile.dast_site.url
              )
            })

            if target_url = params.delete(:target_url)
              params[:dast_site] = DastSites::FindOrCreateService.new(project, current_user).execute!(url: target_url)
            end

            handle_secret_variable!(params, :request_headers, ::Dast::SiteProfileSecretVariable::REQUEST_HEADERS)
            handle_secret_variable!(params, :auth_password, ::Dast::SiteProfileSecretVariable::PASSWORD)

            params.compact!
            dast_site_profile.update!(params)
            auditor.execute

            ServiceResponse.success(payload: dast_site_profile)
          end
        rescue Rollback => e
          ServiceResponse.error(message: e.errors)
        rescue ActiveRecord::RecordNotFound => e
          ServiceResponse.error(message: _('%{model_name} not found') % { model_name: e.model })
        rescue ActiveRecord::RecordInvalid => e
          ServiceResponse.error(message: e.record.errors.full_messages)
        end

        private

        def allowed?
          Ability.allowed?(current_user, :create_on_demand_dast_scan, project)
        end

        def referenced_in_security_policy?
          dast_site_profile.referenced_in_security_policies.present?
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find_dast_site_profile!(id)
          @dast_site_profile = DastSiteProfilesFinder.new(project_id: project.id, id: id).execute.first!
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def handle_secret_variable!(params, arg, key)
          value = params.delete(arg)
          return ServiceResponse.success unless value

          return delete_secret_variable!(key) if value == ''

          response = ::Dast::SiteProfileSecretVariables::CreateOrUpdateService.new(
            container: project,
            current_user: current_user,
            params: { dast_site_profile: dast_site_profile, key: key, raw_value: value }
          ).execute

          raise Rollback, response.errors if response.error?

          response
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def delete_secret_variable!(key)
          variable = dast_site_profile.secret_variables.find_by(key: key)

          return ServiceResponse.success unless variable

          response = ::Dast::SiteProfileSecretVariables::DestroyService.new(
            container: project,
            current_user: current_user,
            params: { dast_site_profile_secret_variable: variable }
          ).execute

          raise Rollback, response.errors if response.error?

          response
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
