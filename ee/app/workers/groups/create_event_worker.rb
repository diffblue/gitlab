# frozen_string_literal: true

module Groups
  class CreateEventWorker
    include ApplicationWorker

    data_consistency :delayed
    idempotent!
    feature_category :onboarding
    urgency :throttled

    def perform(group_id, current_user_id, action)
      Event.create!({
        group_id: group_id,
        action: action,
        author_id: current_user_id
      })
    end
  end
end
