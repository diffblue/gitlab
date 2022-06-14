# frozen_string_literal: true

module IncidentManagement
  module TimelineEvents
    DEFAULT_ACTION = 'comment'
    DEFAULT_EDITABLE = false
    DEFAULT_SKIP_NOTIFICATIONS = false

    class CreateService < TimelineEvents::BaseService
      def initialize(incident, user, params)
        @project = incident.project
        @incident = incident
        @user = user
        @params = params
        @skip_notifications = !!params.fetch(:skip_notifications, DEFAULT_SKIP_NOTIFICATIONS)
      end

      def execute
        return error_no_permissions unless allowed?

        timeline_event_params = {
          project: project,
          incident: incident,
          author: user,
          note: params[:note],
          action: params.fetch(:action, DEFAULT_ACTION),
          note_html: params[:note_html].presence || params[:note],
          occurred_at: params[:occurred_at],
          promoted_from_note: params[:promoted_from_note],
          editable: params.fetch(:editable, DEFAULT_EDITABLE)
        }

        timeline_event = IncidentManagement::TimelineEvent.new(timeline_event_params)

        if timeline_event.save
          add_system_note(timeline_event)

          track_usage_event(:incident_management_timeline_event_created, user.id)
          success(timeline_event)
        else
          error_in_save(timeline_event)
        end
      end

      private

      attr_reader :project, :user, :incident, :params, :skip_notifications

      def add_system_note(timeline_event)
        return if skip_notifications
        return unless Feature.enabled?(:incident_timeline, project)

        SystemNoteService.add_timeline_event(timeline_event)
      end
    end
  end
end
