# frozen_string_literal: true

module Mutations
  module DastSiteTokens
    class Create < BaseMutation
      graphql_name 'DastSiteTokenCreate'

      include FindsProject

      field :id, ::Types::GlobalIDType[::DastSiteToken],
            null: true,
            description: 'ID of the site token.'

      field :token, GraphQL::Types::String,
            null: true,
            description: 'Token string.'

      field :status, Types::DastSiteProfileValidationStatusEnum,
            null: true,
            description: 'Current validation status of the target.'

      argument :full_path, GraphQL::Types::ID,
               required: true,
               description: 'Project the site token belongs to.'

      argument :target_url, GraphQL::Types::String,
               required: false,
               description: 'URL of the target to be validated.'

      authorize :create_on_demand_dast_scan

      def resolve(full_path:, target_url:)
        project = authorized_find!(full_path)

        response = ::AppSec::Dast::SiteTokens::FindOrCreateService.new(
          project: project,
          params: { target_url: target_url }
        ).execute

        return error_response(response.errors) if response.error?

        success_response(response.payload[:dast_site_token], response.payload[:status])
      end

      private

      def error_response(errors)
        { errors: errors }
      end

      def success_response(dast_site_token, status)
        { errors: [], id: dast_site_token.to_global_id, status: status, token: dast_site_token.token }
      end
    end
  end
end
