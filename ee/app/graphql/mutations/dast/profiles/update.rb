# frozen_string_literal: true

module Mutations
  module Dast
    module Profiles
      class Update < BaseMutation
        graphql_name 'DastProfileUpdate'

        ProfileID = ::Types::GlobalIDType[::Dast::Profile]
        SiteProfileID = ::Types::GlobalIDType[::DastSiteProfile]
        ScannerProfileID = ::Types::GlobalIDType[::DastScannerProfile]

        field :dast_profile, ::Types::Dast::ProfileType,
              null: true,
              description: 'Updated profile.'

        field :pipeline_url, GraphQL::Types::String,
              null: true,
              description: 'The URL of the pipeline that was created. Requires the input ' \
                           'argument `runAfterUpdate` to be set to `true` when calling the ' \
                           'mutation, otherwise no pipeline will be created.'

        argument :id, ProfileID,
                 required: true,
                 description: 'ID of the profile to be deleted.'

        argument :full_path, GraphQL::Types::ID,
                 required: false,
                 deprecated: { reason: 'Full path not required to qualify Global ID', milestone: '14.5' },
                 description: 'Project the profile belongs to.'

        argument :dast_profile_schedule, ::Types::Dast::ProfileScheduleInputType,
                 required: false,
                 description: 'Represents a DAST profile schedule.'

        argument :name, GraphQL::Types::String,
                 required: false,
                 description: 'Name of the profile.'

        argument :description, GraphQL::Types::String,
                 required: false,
                 description: 'Description of the profile. Defaults to an empty string.',
                 default_value: ''

        argument :branch_name, GraphQL::Types::String,
                 required: false,
                 description: 'Associated branch.'

        argument :dast_site_profile_id, SiteProfileID,
                 required: false,
                 description: 'ID of the site profile to be associated.'

        argument :dast_scanner_profile_id, ScannerProfileID,
                 required: false,
                 description: 'ID of the scanner profile to be associated.'

        argument :run_after_update, GraphQL::Types::Boolean,
                 required: false,
                 description: 'Run scan using profile after update. Defaults to false.',
                 default_value: false

        argument :tag_list, [GraphQL::Types::String],
                 required: false,
                 description: 'Indicates the runner tags associated with the profile.'

        authorize :create_on_demand_dast_scan

        def resolve(id:, name:, description:, full_path: nil, branch_name: nil, dast_scanner_profile_id: nil, run_after_update: false, **args)
          dast_profile = authorized_find!(id: id)

          params = {
            dast_profile: dast_profile,
            name: name,
            description: description,
            branch_name: branch_name,
            dast_site_profile_id: args[:dast_site_profile_id]&.model_id,
            dast_scanner_profile_id: dast_scanner_profile_id&.model_id,
            dast_profile_schedule: args[:dast_profile_schedule],
            run_after_update: run_after_update
          }

          params[:tag_list] = args[:tag_list] if Feature.enabled?(:on_demand_scans_runner_tags, dast_profile.project)

          response = ::AppSec::Dast::Profiles::UpdateService.new(
            project: dast_profile.project,
            current_user: current_user,
            params: params.compact
          ).execute

          { errors: response.errors, **response.payload }
        end
      end
    end
  end
end
