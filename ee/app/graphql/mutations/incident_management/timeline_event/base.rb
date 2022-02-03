# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module TimelineEvent
      class Base < BaseMutation
        field :timeline_event,
              ::Types::IncidentManagement::TimelineEventType,
              null: true,
              description: 'Timeline event.'

        authorize :admin_incident_management_timeline_event

        private

        def response(result)
          {
            timeline_event: result.payload[:timeline_event],
            errors: result.errors
          }
        end

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::IncidentManagement::TimelineEvent).sync
        end

        def authorize!(object)
          raise_feature_not_available! if object && !timeline_events_available?(object)

          super
        end

        def raise_feature_not_available!
          raise_resource_not_available_error! 'Timeline events are not supported for this project'
        end

        def timeline_events_available?(object)
          ::Gitlab::IncidentManagement.timeline_events_available?(object.project)
        end
      end
    end
  end
end
