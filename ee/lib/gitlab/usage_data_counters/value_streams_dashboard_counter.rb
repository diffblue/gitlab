# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class ValueStreamsDashboardCounter < BaseCounter
      KNOWN_EVENTS = %w[views].freeze
      PREFIX = 'value_streams_dashboard'
    end
  end
end
