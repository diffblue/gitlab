# frozen_string_literal: true

module GeoInstrumentation
  extend ActiveSupport::Concern

  included do
    before_action :track_geo_proxy_event, only: [:show]
  end

  def track_geo_proxy_event
    return unless ::Gitlab::Geo.proxied_request?(request.env) && current_user

    Gitlab::UsageDataCounters::HLLRedisCounter.track_event('g_geo_proxied_requests', values: current_user.id)
  end
end
