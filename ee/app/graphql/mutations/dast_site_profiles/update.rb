# frozen_string_literal: true

module Mutations
  module DastSiteProfiles
    class Update < BaseMutation
      include FindsProject

      graphql_name 'DastSiteProfileUpdate'

      SiteProfileID = ::Types::GlobalIDType[::DastSiteProfile]

      field :id, SiteProfileID,
            null: true,
            description: 'ID of the site profile.'

      argument :full_path, GraphQL::Types::ID,
               required: true,
               description: 'The project the site profile belongs to.'

      argument :id, SiteProfileID,
               required: true,
               description: 'ID of the site profile to be updated.'

      argument :profile_name, GraphQL::Types::String,
               required: true,
               description: 'The name of the site profile.'

      argument :target_url, GraphQL::Types::String,
               required: false,
               description: 'The URL of the target to be scanned.'

      argument :target_type, Types::DastTargetTypeEnum,
               required: false,
               description: 'The type of target to be scanned.'

      argument :excluded_urls, [GraphQL::Types::String],
               required: false,
               description: 'The URLs to skip during an authenticated scan.'

      argument :request_headers, GraphQL::Types::String,
               required: false,
               description: 'Comma-separated list of request header names and values to be ' \
                            'added to every request made by DAST.'

      argument :auth, ::Types::Dast::SiteProfileAuthInputType,
               required: false,
               description: 'Parameters for authentication.'

      authorize :create_on_demand_dast_scan

      def resolve(full_path:, id:, profile_name:, target_url: nil, **params)
        project = authorized_find!(full_path)

        auth_params = params[:auth] || {}

        # TODO: remove explicit coercion once compatibility layer has been removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        dast_site_profile_params = {
          id: SiteProfileID.coerce_isolated_input(id).model_id,
          name: profile_name,
          target_url: target_url,
          target_type: params[:target_type],
          excluded_urls: params[:excluded_urls],
          request_headers: params[:request_headers],
          auth_enabled: auth_params[:enabled],
          auth_url: auth_params[:url],
          auth_username_field: auth_params[:username_field],
          auth_password_field: auth_params[:password_field],
          auth_username: auth_params[:username],
          auth_password: auth_params[:password]
        }.compact

        result = ::AppSec::Dast::SiteProfiles::UpdateService.new(project, current_user).execute(**dast_site_profile_params)

        { id: result.payload.try(:to_global_id), errors: result.errors }
      end
    end
  end
end
