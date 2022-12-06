# frozen_string_literal: true

# GitlabSubscriptionHistory records the previous value before change.
# `gitlab_subscription_created` is not used. Because there is no previous value before creation.
class GitlabSubscriptionHistory < ApplicationRecord
  enum change_type: [:gitlab_subscription_created,
                     :gitlab_subscription_updated,
                     :gitlab_subscription_destroyed]

  validates :gitlab_subscription_id, presence: true

  PREFIXED_ATTRIBUTES = %w[
    id
    created_at
    updated_at
  ].freeze

  TRACKED_ATTRIBUTES = %w[
    start_date
    end_date
    trial_ends_on
    namespace_id
    hosted_plan_id
    max_seats_used
    seats
    trial
    trial_starts_on
    auto_renew
    trial_extension_type
  ].freeze

  # Attributes can be added to this list if they should not be tracked by the history table.
  # By default, attributes should be tracked, and only added to this list if there is a
  # good reason not to.
  # We don't use this list other than to raise awareness of which attributes we should not track.
  OMITTED_ATTRIBUTES = %w[
    seats_in_use
    seats_owed
    max_seats_used_changed_at
    last_seat_refresh_at
  ].freeze

  def self.create_from_change(change_type, attrs)
    create_attrs = attrs
      .slice(*TRACKED_ATTRIBUTES)
      .merge(change_type: change_type)

    PREFIXED_ATTRIBUTES.each do |attr_name|
      create_attrs["gitlab_subscription_#{attr_name}"] = attrs[attr_name]
    end

    GitlabSubscriptionHistory.create(create_attrs)
  end
end
