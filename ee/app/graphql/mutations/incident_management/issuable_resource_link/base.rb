# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module IssuableResourceLink
      class Base < BaseMutation
        field :issuable_resource_link,
              ::Types::IncidentManagement::IssuableResourceLinkType,
              null: true,
              description: 'Issuable resource link.'

        authorize :admin_issuable_resource_link

        private

        def response(result)
          {
            issuable_resource_link: result.payload[:issuable_resource_link],
            errors: result.errors
          }
        end

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::Issue).sync
        end
      end
    end
  end
end
