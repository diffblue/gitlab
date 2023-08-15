# frozen_string_literal: true

module GovernUsageTracking
  include ProductAnalyticsTracking
  extend ActiveSupport::Concern

  included do
    def self.track_govern_activity(page_name, *controller_actions, conditions: nil)
      track_event(*controller_actions,
        name: "users_visiting_#{page_name}",
        action: 'user_perform_visit',
        label: "redis_hll_counters.govern.users_visiting_#{page_name}_monthly",
        conditions: conditions,
        destinations: %i[redis_hll snowplow]) { |context| context.current_user&.id }
    end
  end
end
