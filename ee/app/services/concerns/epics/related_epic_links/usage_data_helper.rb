# frozen_string_literal: true

# Helper to simplify recording related epics unique events on services.
# Used by RelatedEpicLinks::CreateService and RelatedEpicLinks::DestroyService
#
# Calls the following methods on Gitlab::UsageDataCounters::EpicActivityUniqueCounter:
#
# track_linked_epic_with_type_relates_to_added
# track_linked_epic_with_type_relates_to_removed
# track_linked_epic_with_type_blocks_added
# track_linked_epic_with_type_blocks_removed
# track_linked_epic_with_type_is_blocked_by_added
# track_linked_epic_with_type_is_blocked_by_removed
module Epics::RelatedEpicLinks::UsageDataHelper
  ALLOWED_LINK_TYPES =
    [
      IssuableLink::TYPE_RELATES_TO,
      IssuableLink::TYPE_BLOCKS,
      IssuableLink::TYPE_IS_BLOCKED_BY
    ].freeze

  ALLOWED_EVENT_TYPES = [:added, :removed].freeze

  private

  def track_related_epics_event_for(link_type:, event_type:, namespace:)
    return unless ALLOWED_LINK_TYPES.include?(link_type)
    return unless ALLOWED_EVENT_TYPES.include?(event_type)

    event_method_name = "track_linked_epic_with_type_#{link_type}_#{event_type}"

    Gitlab::UsageDataCounters::EpicActivityUniqueCounter
      .method(event_method_name)
      .call(author: current_user, namespace: namespace)
  end
end
