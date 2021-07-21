# frozen_string_literal: true

module Mutations
  module Dast
    module Profiles
      class Create < BaseMutation
        include FindsProject

        graphql_name 'DastProfileCreate'

        field :dast_profile, ::Types::Dast::ProfileType,
              null: true,
              description: 'The created profile.'

        field :pipeline_url, GraphQL::Types::String,
              null: true,
              description: 'The URL of the pipeline that was created. Requires `runAfterCreate` to be set to `true`.'

        argument :full_path, GraphQL::Types::ID,
                 required: true,
                 description: 'The project the profile belongs to.'

        argument :name, GraphQL::Types::String,
                 required: true,
                 description: 'The name of the profile.'

        argument :description, GraphQL::Types::String,
                 required: false,
                 description: 'The description of the profile. Defaults to an empty string.',
                 default_value: ''

        argument :branch_name, GraphQL::Types::String,
                 required: false,
                 description: 'The associated branch.'

        argument :dast_site_profile_id, ::Types::GlobalIDType[::DastSiteProfile],
                 required: true,
                 description: 'ID of the site profile to be associated.'

        argument :dast_scanner_profile_id, ::Types::GlobalIDType[::DastScannerProfile],
                 required: true,
                 description: 'ID of the scanner profile to be associated.'

        argument :run_after_create, GraphQL::Types::Boolean,
                 required: false,
                 description: 'Run scan using profile after creation. Defaults to false.',
                 default_value: false

        authorize :create_on_demand_dast_scan

        def resolve(full_path:, name:, description: '', branch_name: nil, dast_site_profile_id:, dast_scanner_profile_id:, run_after_create: false)
          project = authorized_find!(full_path)
          raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless allowed?(project)

          # TODO: remove explicit coercion once compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          site_profile_id = ::Types::GlobalIDType[::DastSiteProfile].coerce_isolated_input(dast_site_profile_id)
          scanner_profile_id = ::Types::GlobalIDType[::DastScannerProfile].coerce_isolated_input(dast_scanner_profile_id)

          dast_site_profile = project.dast_site_profiles.find(site_profile_id.model_id)
          dast_scanner_profile = project.dast_scanner_profiles.find(scanner_profile_id.model_id)

          response = ::AppSec::Dast::Profiles::CreateService.new(
            container: project,
            current_user: current_user,
            params: {
              project: project,
              name: name,
              description: description,
              branch_name: branch_name,
              dast_site_profile: dast_site_profile,
              dast_scanner_profile: dast_scanner_profile,
              run_after_create: run_after_create
            }
          ).execute

          return { errors: response.errors } if response.error?

          { errors: [], dast_profile: response.payload.fetch(:dast_profile), pipeline_url: response.payload.fetch(:pipeline_url) }
        end

        private

        def allowed?(project)
          project.feature_available?(:security_on_demand_scans)
        end
      end
    end
  end
end
