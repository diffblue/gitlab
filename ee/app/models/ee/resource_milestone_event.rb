# frozen_string_literal: true

module EE
  module ResourceMilestoneEvent
    extend ActiveSupport::Concern

    prepended do
      scope :aliased_for_timebox_report, -> do
        select("'timebox' AS event_type", "id", "created_at", "milestone_id AS value", "action", "issue_id")
      end
    end
  end
end
