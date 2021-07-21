# frozen_string_literal: true

module Mutations
  module DastSiteProfiles
    class Create < BaseMutation
      include FindsProject

      graphql_name 'DastSiteProfileCreate'

      field :id, ::Types::GlobalIDType[::DastSiteProfile],
            null: true,
            description: 'ID of the site profile.'

      argument :full_path, GraphQL::Types::ID,
               required: true,
               description: 'The project the site profile belongs to.'

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
               default_value: [],
               description: 'The URLs to skip during an authenticated scan. Defaults to `[]`.'

      argument :request_headers, GraphQL::Types::String,
               required: false,
               description: 'Comma-separated list of request header names and values to be ' \
                            'added to every request made by DAST.'

      argument :auth, ::Types::Dast::SiteProfileAuthInputType,
               required: false,
               description: 'Parameters for authentication.'

      authorize :create_on_demand_dast_scan

      def resolve(full_path:, profile_name:, target_url: nil, **params)
        project = authorized_find!(full_path)

        auth_params = params[:auth] || {}

        dast_site_profile_params = {
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

        result = ::AppSec::Dast::SiteProfiles::CreateService.new(project, current_user).execute(**dast_site_profile_params)

        { id: result.payload.try(:to_global_id), errors: result.errors }
      end
    end
  end
end
