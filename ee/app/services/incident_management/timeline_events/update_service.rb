# frozen_string_literal: true

module IncidentManagement
  module TimelineEvents
    # @param timeline_event [IncidentManagement::TimelineEvent]
    # @param user [User]
    # @param params [Hash]
    # @option params [string] note
    # @option params [datetime] occurred_at
    class UpdateService < TimelineEvents::BaseService
      def initialize(timeline_event, user, params)
        @timeline_event = timeline_event
        @incident = timeline_event.incident
        @user = user
        @note = params[:note]
        @occurred_at = params[:occurred_at]
      end

      def execute
        return error_no_permissions unless allowed?

        if timeline_event.update(update_params)
          success(timeline_event)
        else
          error_in_save(timeline_event)
        end
      end

      private

      attr_reader :timeline_event, :incident, :user, :note, :occurred_at

      def update_params
        { updated_by_user: user, note: note.presence, occurred_at: occurred_at.presence }.compact
      end
    end
  end
end
