# frozen_string_literal: true

module Mutations
  module DastSiteValidations
    class Create < BaseMutation
      graphql_name 'DastSiteValidationCreate'

      include FindsProject

      field :id, ::Types::GlobalIDType[::DastSiteValidation],
            null: true,
            description: 'ID of the site validation.'

      field :status, ::Types::DastSiteProfileValidationStatusEnum,
            null: true,
            description: 'Current validation status.'

      argument :full_path, GraphQL::Types::ID,
               required: true,
               description: 'Project the site profile belongs to.'

      argument :dast_site_token_id, ::Types::GlobalIDType[::DastSiteToken],
               required: true,
               description: 'ID of the site token.'

      argument :validation_path, GraphQL::Types::String,
               required: true,
               description: 'Path to be requested during validation.'

      argument :strategy, ::Types::DastSiteValidationStrategyEnum,
               required: false,
               description: 'Validation strategy to be used.'

      authorize :create_on_demand_dast_scan

      def resolve(full_path:, dast_site_token_id:, validation_path:, strategy: :text_file)
        project = authorized_find!(full_path)

        dast_site_token = dast_site_token_id.find

        response = ::AppSec::Dast::SiteValidations::FindOrCreateService.new(
          container: project,
          current_user: current_user,
          params: {
            dast_site_token: dast_site_token,
            url_path: validation_path,
            validation_strategy: strategy
          }
        ).execute

        return error_response(response.errors) if response.error?

        success_response(response.payload)
      end

      private

      def error_response(errors)
        { errors: errors }
      end

      def success_response(dast_site_validation)
        { errors: [], id: dast_site_validation.to_global_id, status: dast_site_validation.state }
      end
    end
  end
end
