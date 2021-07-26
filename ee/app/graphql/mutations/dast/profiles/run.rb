# frozen_string_literal: true

module Mutations
  module Dast
    module Profiles
      class Run < BaseMutation
        include FindsProject

        graphql_name 'DastProfileRun'

        ProfileID = ::Types::GlobalIDType[::Dast::Profile]

        field :pipeline_url, GraphQL::Types::String,
              null: true,
              description: 'URL of the pipeline that was created.'

        argument :full_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Full path for the project the scanner profile belongs to.'

        argument :id, ProfileID,
                 required: true,
                 description: 'ID of the profile to be used for the scan.'

        authorize :create_on_demand_dast_scan

        def resolve(full_path:, id:)
          project = authorized_find!(full_path)
          raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless allowed?(project)

          # TODO: remove this line once the compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          id = ProfileID.coerce_isolated_input(id).model_id

          dast_profile = find_dast_profile(project, id)
          return { errors: ['Profile not found for given parameters'] } unless dast_profile

          response = create_on_demand_dast_scan(project, dast_profile)

          return { errors: response.errors } if response.error?

          { errors: [], pipeline_url: response.payload.fetch(:pipeline_url) }
        end

        private

        def allowed?(project)
          project.feature_available?(:security_on_demand_scans)
        end

        def find_dast_profile(project, id)
          ::Dast::ProfilesFinder.new(project_id: project.id, id: id)
            .execute
            .first
        end

        def create_on_demand_dast_scan(project, dast_profile)
          ::DastOnDemandScans::CreateService.new(
            container: project,
            current_user: current_user,
            params: { dast_profile: dast_profile }
          ).execute
        end
      end
    end
  end
end
