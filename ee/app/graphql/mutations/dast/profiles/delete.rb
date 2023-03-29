# frozen_string_literal: true

module Mutations
  module Dast
    module Profiles
      class Delete < BaseMutation
        graphql_name 'DastProfileDelete'

        ProfileID = ::Types::GlobalIDType[::Dast::Profile]

        argument :id, ProfileID,
                 required: true,
                 description: 'ID of the profile to be deleted.'

        authorize :create_on_demand_dast_scan

        def resolve(id:)
          dast_profile = authorized_find!(id: id)

          response = ::AppSec::Dast::Profiles::DestroyService.new(
            container: dast_profile.project,
            current_user: current_user,
            params: { dast_profile: dast_profile }
          ).execute

          { errors: response.errors }
        end
      end
    end
  end
end
