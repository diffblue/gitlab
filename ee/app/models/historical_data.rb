# frozen_string_literal: true

class HistoricalData < ApplicationRecord
  validates :recorded_at, presence: true

  # HistoricalData.during((Time.current - 1.year)..Time.current).average(:active_user_count)
  scope :during, ->(range) { where(recorded_at: range) }

  class << self
    def track!
      create!(
        recorded_at: Time.current,
        active_user_count: License.load_license&.daily_billable_users_count
      )
    end

    def max_historical_user_count(from:, to:)
      HistoricalData.during(from..to).maximum(:active_user_count) || 0
    end
  end
end
