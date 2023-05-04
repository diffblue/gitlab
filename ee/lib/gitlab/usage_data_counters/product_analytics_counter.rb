# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class ProductAnalyticsCounter < BaseCounter
      KNOWN_EVENTS = %w[view_dashboard].freeze
      PREFIX = 'product_analytics'
    end
  end
end
