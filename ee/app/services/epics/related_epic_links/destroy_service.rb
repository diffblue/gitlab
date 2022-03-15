# frozen_string_literal: true

module Epics
  module RelatedEpicLinks
    class DestroyService < ::IssuableLinks::DestroyService
      private

      def permission_to_remove_relation?
        can?(current_user, :admin_related_epic_link, source) && can?(current_user, :admin_epic, target)
      end

      def track_event
        # No op
      end

      def not_found_message
        'No Related Epic Link found'
      end
    end
  end
end
