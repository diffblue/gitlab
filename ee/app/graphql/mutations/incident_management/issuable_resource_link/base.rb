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
      end
    end
  end
end
