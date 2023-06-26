# frozen_string_literal: true

class TierBadgeExperiment < ApplicationExperiment
  candidate { true }
  exclude { context.namespace.created_at.to_date != 14.days.ago.to_date }
end
