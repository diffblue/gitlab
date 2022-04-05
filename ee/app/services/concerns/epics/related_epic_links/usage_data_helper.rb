# frozen_string_literal: true

module Epics::RelatedEpicLinks::UsageDataHelper
  ALLOWED_LINK_TYPES =
    [
      IssuableLink::TYPE_RELATES_TO,
      IssuableLink::TYPE_BLOCKS,
      IssuableLink::TYPE_IS_BLOCKED_BY
    ].freeze

  ALLOWED_EVENT_TYPES = [:added, :removed].freeze

  def track_related_epics_event_for(link_type:, event_type:)
    return unless ALLOWED_LINK_TYPES.include?(link_type)
    return unless ALLOWED_EVENT_TYPES.include?(event_type)

    event_method_name = "track_linked_epic_with_type_#{link_type}_#{event_type}"

    Gitlab::UsageDataCounters::EpicActivityUniqueCounter
      .method(event_method_name)
      .call(author: current_user)
  end
end
