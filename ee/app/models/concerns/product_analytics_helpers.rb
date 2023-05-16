# frozen_string_literal: true

module ProductAnalyticsHelpers
  extend ActiveSupport::Concern

  def product_analytics_enabled?
    return false unless licensed_feature_available?(:product_analytics)
    return false unless ::Feature.enabled?(:product_analytics_dashboards, self)

    true
  end

  def product_analytics_dashboards
    return [] unless product_analytics_enabled?

    ::ProductAnalytics::Dashboard.for_project(self)
  end

  def product_analytics_funnels
    return [] unless product_analytics_enabled?

    ::ProductAnalytics::Funnel.for_project(self)
  end

  def product_analytics_dashboard(slug)
    return unless product_analytics_enabled?

    product_analytics_dashboards.find { |dashboard| dashboard.slug == slug }
  end
end
