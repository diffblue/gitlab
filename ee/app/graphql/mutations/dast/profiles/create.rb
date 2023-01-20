# frozen_string_literal: true

module Mutations
  module Dast
    module Profiles
      class Create < BaseMutation
        graphql_name 'DastProfileCreate'

        include FindsProject

        field :dast_profile, ::Types::Dast::ProfileType,
              null: true,
              description: 'Created profile.'

        field :pipeline_url, GraphQL::Types::String,
              null: true,
              description: 'URL of the pipeline that was created. Requires `runAfterCreate` to be set to `true`.'

        argument :full_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Project the profile belongs to.'

        argument :dast_profile_schedule, ::Types::Dast::ProfileScheduleInputType,
              required: false,
              description: 'Represents a DAST Profile Schedule.'

        argument :name, GraphQL::Types::String,
                 required: true,
                 description: 'Name of the profile.'

        argument :description, GraphQL::Types::String,
                 required: false,
                 description: 'Description of the profile. Defaults to an empty string.',
                 default_value: ''

        argument :branch_name, GraphQL::Types::String,
                 required: false,
                 description: 'Associated branch.'

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

        argument :tag_list, [GraphQL::Types::String],
                 required: false,
                 description: 'Indicates the runner tags associated with the profile.'

        authorize :create_on_demand_dast_scan

        def resolve(**args)
          project = authorized_find!(args.delete(:full_path))

          dast_site_profile = project.dast_site_profiles.find(args.delete(:dast_site_profile_id).model_id)
          dast_scanner_profile = project.dast_scanner_profiles.find(args.delete(:dast_scanner_profile_id).model_id)

          args.delete(:tag_list) unless Feature.enabled?(:on_demand_scans_runner_tags, project)

          response = ::AppSec::Dast::Profiles::CreateService.new(
            project: project,
            current_user: current_user,
            params: args.merge({ dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile })
          ).execute

          return { errors: response.errors } if response.error?

          build_response(response.payload)
        end

        private

        def build_response(payload)
          {
            errors: [],
            dast_profile: payload.fetch(:dast_profile),
            pipeline_url: payload.fetch(:pipeline_url),
            dast_profile_schedule: payload.fetch(:dast_profile_schedule)
          }
        end
      end
    end
  end
end
