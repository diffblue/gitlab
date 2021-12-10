# frozen_string_literal: true

module GeoInstrumentation
  extend ActiveSupport::Concern

  included do
    before_action :track_geo_proxy_event, only: [:show]
  end

  def track_geo_proxy_event
    return unless Feature.enabled?(:track_geo_proxy_events, default_enabled: :yaml) && ::Gitlab::Geo.proxied_request?(request.env)
    return unless current_user

    Gitlab::UsageDataCounters::HLLRedisCounter.track_event('g_geo_proxied_requests', values: current_user.id)
  end
end
