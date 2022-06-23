# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module IssuableResourceLink
      class Destroy < Base
        graphql_name 'IssuableResourceLinkDestroy'

        argument :id, Types::GlobalIDType[::IncidentManagement::IssuableResourceLink],
                required: true,
                description: 'Issuable resource link ID to remove.'

        def resolve(id:)
          issuable_resource_link = authorized_find!(id: id)

          response ::IncidentManagement::IssuableResourceLinks::DestroyService.new(
            issuable_resource_link,
            current_user
          ).execute
        end

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::IncidentManagement::IssuableResourceLink).sync
        end
      end
    end
  end
end
