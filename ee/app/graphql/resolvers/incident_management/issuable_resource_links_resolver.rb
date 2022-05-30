# frozen_string_literal: true

module Resolvers
  module IncidentManagement
    class IssuableResourceLinksResolver < BaseResolver
      include LooksAhead

      type ::Types::IncidentManagement::IssuableResourceLinkType.connection_type, null: true

      argument :incident_id,
               ::Types::GlobalIDType[::Issue],
               required: true,
               description: 'ID of the incident.'

      when_single do
        argument :id,
                 ::Types::GlobalIDType[::IncidentManagement::IssuableResourceLink],
                 required: true,
                 description: 'ID of the issuable resource link.',
                 prepare: ->(id, ctx) { id.model_id }
      end

      def resolve(**args)
        incident = args[:incident_id].find

        apply_lookahead(::IncidentManagement::IssuableResourceLinksFinder.new(current_user, incident, args).execute)
      end
    end
  end
end
