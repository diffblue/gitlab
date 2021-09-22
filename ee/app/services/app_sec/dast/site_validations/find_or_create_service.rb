# frozen_string_literal: true

module AppSec
  module Dast
    module SiteValidations
      class FindOrCreateService < BaseContainerService
        def execute
          return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

          dast_site_validation = existing_successful_validation || create_validation!

          return ServiceResponse.error(message: 'Site does not exist for profile') unless dast_site_validation.dast_site

          associate_dast_site!(dast_site_validation)

          return ServiceResponse.success(payload: dast_site_validation) if dast_site_validation.passed?

          perform_runner_validation(dast_site_validation)
        rescue ActiveRecord::RecordInvalid => err
          ServiceResponse.error(message: err.record.errors.full_messages)
        rescue KeyError => err
          ServiceResponse.error(message: err.message.capitalize)
        end

        private

        def allowed?
          can?(current_user, :create_on_demand_dast_scan, container) &&
            dast_site_token.project == container
        end

        def dast_site_token
          @dast_site_token ||= params.fetch(:dast_site_token)
        end

        def url_path
          @url_path ||= params.fetch(:url_path)
        end

        def validation_strategy
          @validation_strategy ||= params.fetch(:validation_strategy)
        end

        def existing_successful_validation
          @existing_successful_validation ||= find_latest_successful_dast_site_validation
        end

        def url_base
          @url_base ||= DastSiteValidation.get_normalized_url_base(dast_site_token.url)
        end

        def associate_dast_site!(dast_site_validation)
          dast_site_validation.dast_site.update!(dast_site_validation_id: dast_site_validation.id)
        end

        def find_latest_successful_dast_site_validation
          DastSiteValidationsFinder.new(
            project_id: container.id,
            state: :passed,
            url_base: url_base
          ).execute.first
        end

        def create_validation!
          DastSiteValidation.create!(
            dast_site_token: dast_site_token,
            url_path: url_path,
            validation_strategy: validation_strategy
          )
        end

        def perform_runner_validation(dast_site_validation)
          AppSec::Dast::SiteValidations::RunnerService.new(
            project: dast_site_validation.project,
            current_user: current_user,
            params: { dast_site_validation: dast_site_validation }
          ).execute
        end
      end
    end
  end
end
