# frozen_string_literal: true

module Mutations
  module Dast
    module Profiles
      class Run < BaseMutation
        graphql_name 'DastProfileRun'

        ProfileID = ::Types::GlobalIDType[::Dast::Profile]

        field :pipeline_url, GraphQL::Types::String,
              null: true,
              description: 'URL of the pipeline that was created.'

        argument :full_path, GraphQL::Types::ID,
                 required: false,
                 deprecated: { reason: 'Full path not required to qualify Global ID', milestone: '14.5' },
                 description: 'Full path for the project the scanner profile belongs to.'

        argument :id, ProfileID,
                 required: true,
                 description: 'ID of the profile to be used for the scan.'

        authorize :create_on_demand_dast_scan

        def resolve(id:, full_path: nil)
          dast_profile = authorized_find!(id: id)

          response = create_on_demand_dast_scan(dast_profile)

          return { errors: response.errors } if response.error?

          { errors: [], pipeline_url: response.payload.fetch(:pipeline_url) }
        end

        private

        def create_on_demand_dast_scan(dast_profile)
          ::AppSec::Dast::Scans::CreateService.new(
            container: dast_profile.project,
            current_user: current_user,
            params: { dast_profile: dast_profile }
          ).execute
        end
      end
    end
  end
end
