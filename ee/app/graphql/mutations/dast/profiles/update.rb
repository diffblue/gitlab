# frozen_string_literal: true

module Mutations
  module Dast
    module Profiles
      class Update < BaseMutation
        include FindsProject

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
                 required: true,
                 description: 'Project the profile belongs to.'

        argument :dast_profile_schedule, ::Types::Dast::ProfileScheduleInputType,
              required: false,
              description: 'Represents a DAST profile schedule. Results in an error if `dast_on_demand_scans_scheduler` feature flag is disabled.'

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

        authorize :create_on_demand_dast_scan

        def resolve(full_path:, id:, name:, description:, branch_name: nil, dast_scanner_profile_id: nil, run_after_update: false, **args)
          project = authorized_find!(full_path)
          raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless allowed?(args[:dast_profile_schedule], project)

          dast_profile = find_dast_profile(project.id, id)
          authorize!(dast_profile)

          params = {
            dast_profile: dast_profile,
            name: name,
            description: description,
            branch_name: branch_name,
            dast_site_profile_id: as_model_id(SiteProfileID, args[:dast_site_profile_id]),
            dast_scanner_profile_id: as_model_id(ScannerProfileID, dast_scanner_profile_id),
            dast_profile_schedule: args[:dast_profile_schedule],
            run_after_update: run_after_update
          }.compact

          response = ::AppSec::Dast::Profiles::UpdateService.new(
            container: project,
            current_user: current_user,
            params: params
          ).execute

          { errors: response.errors, **response.payload }
        end

        private

        def allowed?(dast_profile_schedule, project)
          scheduler_flag_enabled?(dast_profile_schedule, project)
        end

        def scheduler_flag_enabled?(dast_profile_schedule, project)
          return true unless dast_profile_schedule

          Feature.enabled?(:dast_on_demand_scans_scheduler, project, default_enabled: :yaml)
        end

        def as_model_id(klass, value)
          return unless value

          # TODO: remove explicit coercion once compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          klass.coerce_isolated_input(value).model_id
        end

        def find_dast_profile(project_id, id)
          # TODO: remove this line once the compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          id = ProfileID.coerce_isolated_input(id).model_id

          ::Dast::ProfilesFinder.new(project_id: project_id, id: id)
            .execute
            .first
        end
      end
    end
  end
end
