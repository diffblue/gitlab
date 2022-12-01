# frozen_string_literal: true

module Mutations
  module DastSiteProfiles
    class Create < BaseMutation
      graphql_name 'DastSiteProfileCreate'

      include FindsProject
      include Mutations::AppSec::Dast::SiteProfiles::SharedArguments

      field :id, SiteProfileID,
            null: true,
            description: 'ID of the site profile.',
            deprecated: { reason: 'use `dastSiteProfile.id` field', milestone: '14.10' }

      field :dast_site_profile, ::Types::DastSiteProfileType,
            null: true,
            description: 'Site Profile object.'

      argument :full_path, GraphQL::Types::ID,
               required: true,
               description: 'Project the site profile belongs to.'

      argument :excluded_urls, [GraphQL::Types::String],
               required: false,
               default_value: [],
               description: 'URLs to skip during an authenticated scan. Defaults to `[]`.'

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
          auth_password: auth_params[:password],
          auth_submit_field: auth_params[:submit_field]
        }.compact

        dast_site_profile_params[:scan_method] = params[:scan_method]
        dast_site_profile_params[:scan_file_path] = params[:scan_file_path]

        result = ::AppSec::Dast::SiteProfiles::CreateService.new(project, current_user).execute(**dast_site_profile_params)

        { id: result.payload.try(:to_global_id), dast_site_profile: result.payload, errors: result.errors }
      end
    end
  end
end
