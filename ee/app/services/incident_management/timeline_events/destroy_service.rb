# frozen_string_literal: true

module IncidentManagement
  module TimelineEvents
    class DestroyService < TimelineEvents::BaseService
      # @param timeline_event [IncidentManagement::TimelineEvent]
      # @param user [User]
      def initialize(timeline_event, user)
        @timeline_event = timeline_event
        @user = user
        @incident = timeline_event.incident
      end

      def execute
        return error_no_permissions unless allowed?

        if timeline_event.destroy
          success(timeline_event)
        else
          error_in_save(timeline_event)
        end
      end

      private

      attr_reader :timeline_event, :user, :incident
    end
  end
end
