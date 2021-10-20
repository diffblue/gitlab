# frozen_string_literal: true

module Mutations
  module DastSiteProfiles
    class Update < BaseMutation
      include FindsProject
      include Mutations::AppSec::Dast::SiteProfiles::SharedArguments

      graphql_name 'DastSiteProfileUpdate'

      field :id, SiteProfileID,
            null: true,
            description: 'ID of the site profile.'

      argument :id, SiteProfileID,
               required: true,
               description: 'ID of the site profile to be updated.'

      argument :excluded_urls, [GraphQL::Types::String],
               required: false,
               description: 'URLs to skip during an authenticated scan.'

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
