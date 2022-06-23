# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module IssuableResourceLink
      class Create < Base
        graphql_name 'IssuableResourceLinkCreate'

        argument :id, Types::GlobalIDType[::Issue],
                  required: true,
                  description: 'Incident id to associate the resource link with.'

        argument :link, GraphQL::Types::String,
                  required: true,
                  description: 'Link of the resource.'

        argument :link_text, GraphQL::Types::String,
                  required: false,
                  description: 'Link text of the resource.'

        argument :link_type, Types::IncidentManagement::IssuableResourceLinkTypeEnum,
                  required: false,
                  description: 'Link type of the resource.'

        def resolve(id:, **args)
          incident = authorized_find!(id: id)

          response ::IncidentManagement::IssuableResourceLinks::CreateService.new(incident, current_user, args).execute
        end

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::Issue).sync
        end
      end
    end
  end
end
