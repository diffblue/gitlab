# frozen_string_literal: true

module IncidentManagement
  module TimelineEvents
    # @param timeline_event [IncidentManagement::TimelineEvent]
    # @param user [User]
    # @param params [Hash]
    # @option params [string] note
    # @option params [datetime] occurred_at
    class UpdateService < TimelineEvents::BaseService
      VALIDATION_CONTEXT = :user_input

      def initialize(timeline_event, user, params)
        @timeline_event = timeline_event
        @incident = timeline_event.incident
        @user = user
        @note = params[:note]
        @occurred_at = params[:occurred_at]
        @validation_context = VALIDATION_CONTEXT
        @timeline_event_tags = params[:timeline_event_tag_names]
      end

      def execute
        return error_no_permissions unless allowed?

        timeline_event.assign_attributes(update_params)
        update_timeline_event_tags(timeline_event, timeline_event_tags) unless timeline_event_tags.nil?

        if timeline_event.save(context: validation_context)
          add_system_note(timeline_event)

          track_usage_event(:incident_management_timeline_event_edited, user.id)
          success(timeline_event)
        else
          error_in_save(timeline_event)
        end
      end

      private

      attr_reader :timeline_event, :incident, :user, :note, :occurred_at, :validation_context, :timeline_event_tags

      def update_params
        { updated_by_user: user, note: note, occurred_at: occurred_at }.compact
      end

      def add_system_note(timeline_event)
        changes = was_changed(timeline_event)
        return if changes == :none

        SystemNoteService.edit_timeline_event(timeline_event, user, was_changed: changes)
      end

      def was_changed(timeline_event)
        changes = timeline_event.previous_changes
        occurred_at_changed = changes.key?('occurred_at')
        note_changed = changes.key?('note')

        return :occurred_at_and_note if occurred_at_changed && note_changed
        return :occurred_at if occurred_at_changed
        return :note if note_changed

        :none
      end

      def update_timeline_event_tags(timeline_event, tag_updates)
        tag_updates = tag_updates.map(&:downcase)
        already_assigned_tags = timeline_event.timeline_event_tags.pluck_names.map(&:downcase)

        tags_to_remove = already_assigned_tags - tag_updates
        tags_to_add = tag_updates - already_assigned_tags

        validate_tags(tags_to_add)

        remove_tag_links(timeline_event, tags_to_remove) if tags_to_remove.any?
        create_tag_links(timeline_event, tags_to_add) if tags_to_add.any?
      end

      def remove_tag_links(timeline_event, tags_to_remove_names)
        tags_to_remove_ids = timeline_event.timeline_event_tags.by_names(tags_to_remove_names).ids

        timeline_event.timeline_event_tag_links.where(timeline_event_tag_id: tags_to_remove_ids).delete_all
      end

      def create_tag_links(timeline_event, tags_to_add_names)
        tags_to_add_ids = timeline_event.project.incident_management_timeline_event_tags.by_names(tags_to_add_names).ids

        tag_links = tags_to_add_ids.map do |tag_id|
          {
            timeline_event_id: timeline_event.id,
            timeline_event_tag_id: tag_id,
            created_at: DateTime.current
          }
        end

        IncidentManagement::TimelineEventTagLink.insert_all(tag_links) if tag_links.any?
      end

      def validate_tags(tags_to_add)
        defined_tags = timeline_event.project.incident_management_timeline_event_tags.by_names(tags_to_add)

        non_existing_tags = tags_to_add - defined_tags

        return if non_existing_tags.empty?

        raise Gitlab::Graphql::Errors::ArgumentError,
          "Following tags don't exist: #{non_existing_tags}"
      end

      def allowed?
        user&.can?(:edit_incident_management_timeline_event, timeline_event)
      end
    end
  end
end
