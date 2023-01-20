# frozen_string_literal: true

module GitlabSubscriptions
  class TrialStatus
    attr_reader :ends_on

    def initialize(starts_on, ends_on)
      @starts_on = starts_on
      @ends_on = ends_on
    end

    def days_remaining
      (ends_on - Date.current).to_i
    end

    def duration
      (ends_on - starts_on).to_i
    end

    def days_used
      used = duration - days_remaining
      used.nonzero? || 1 # prevent showing 0 on day 1 of a trial
    end

    def percentage_complete
      (days_used / duration.to_f * 100).round(2)
    end

    private

    attr_reader :starts_on
  end
end
