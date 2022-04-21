# frozen_string_literal: true

module Epics
  module RelatedEpicLinks
    class DestroyService < ::IssuableLinks::DestroyService
      include UsageDataHelper

      private

      def permission_to_remove_relation?
        can?(current_user, :admin_related_epic_link, source) && can?(current_user, :admin_epic, target)
      end

      def track_event
        track_related_epics_event_for(link_type: link.link_type, event_type: :removed)
      end

      def not_found_message
        'No Related Epic Link found'
      end
    end
  end
end
