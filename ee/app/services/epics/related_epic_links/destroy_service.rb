# frozen_string_literal: true

module Epics
  module RelatedEpicLinks
    class DestroyService < ::IssuableLinks::DestroyService
      include UsageDataHelper
      include Gitlab::Utils::StrongMemoize

      attr_reader :epic, :link_type

      def initialize(link, epic, user)
        @link = link
        @current_user = user
        @source = link.source
        @target = link.target
        @link_type = link.link_type
        @epic = epic
      end

      private

      def permission_to_remove_relation?
        can?(current_user, :admin_epic_link_relation, source) && can?(current_user, :admin_epic_relation, target)
      end

      def track_event
        event_type = get_event_type

        return unless event_type

        track_related_epics_event_for(link_type: event_type, event_type: :removed, namespace: epic.group)
      end

      def get_event_type
        return unless epic_is_link_source? || epic_is_link_target?

        # If the link.link_type is of TYPE_BLOCKS and the epic in context is:
        # - epic_is_link_target? means the epic is blocked by other epic
        # - epic_is_link_source? it means the epic is blocking another epic
        if epic_is_link_target?
          Epic::RelatedEpicLink.inverse_link_type(link_type)
        else
          link_type
        end
      end

      def epic_is_link_source?
        strong_memoize(:epic_is_link_source) { epic == source }
      end

      def epic_is_link_target?
        strong_memoize(:epic_is_link_target) { epic == target }
      end

      def not_found_message
        'No Related Epic Link found'
      end
    end
  end
end
