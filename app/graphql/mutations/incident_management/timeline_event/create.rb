# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module TimelineEvent
      class Create < Base
        graphql_name 'TimelineEventCreate'

        argument :incident_id, Types::GlobalIDType[::Issue],
                 required: true,
                 description: 'Incident ID of the timeline event.'

        argument :note, GraphQL::Types::String,
                 required: true,
                 description: 'Text note of the timeline event.'

        argument :occurred_at, Types::TimeType,
                 required: true,
                 description: 'Timestamp of when the event occurred.'

        argument :timeline_event_tag_names, [GraphQL::Types::String],
                 required: false,
                 description: copy_field_description(Types::IncidentManagement::TimelineEventType, :timeline_event_tags)

        def resolve(incident_id:, **args)
          incident = authorized_find!(id: incident_id)

          authorize!(incident)

          validate_tags(incident.project, args[:timeline_event_tag_names])

          response ::IncidentManagement::TimelineEvents::CreateService.new(
            incident, current_user, args.merge(editable: true)
          ).execute
        end

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::Issue).sync
        end

        def validate_tags(project, tag_names)
          return unless tag_names&.any?

          start_time_tag = ::IncidentManagement::TimelineEventTag::START_TIME_TAG_NAME.downcase
          end_time_tag = ::IncidentManagement::TimelineEventTag::END_TIME_TAG_NAME.downcase

          tag_names_downcased = tag_names.map(&:downcase)

          tags = project.incident_management_timeline_event_tags.by_names(tag_names).pluck_names.map(&:downcase)

          # remove tags from given tag_names and also remove predefined tags which can be auto created
          non_existing_tags = tag_names_downcased - tags - [start_time_tag, end_time_tag]

          return if non_existing_tags.empty?

          raise Gitlab::Graphql::Errors::ArgumentError,
              "Following tags don't exist: #{non_existing_tags}"
        end
      end
    end
  end
end
