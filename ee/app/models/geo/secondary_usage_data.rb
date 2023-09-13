# frozen_string_literal: true

# This class is used to store usage data on a secondary for transmission
# to the primary during a status update.
class Geo::SecondaryUsageData < Geo::TrackingBase
  include Gitlab::Utils::UsageData

  GIT_FETCH_EVENT_COUNT_WEEKLY_QUERY = 'round(sum(increase(grpc_server_handled_total{grpc_method=~"SSHUploadPack|PostUploadPack"}[7d])))'
  GIT_PUSH_EVENT_COUNT_WEEKLY_QUERY = 'round(sum(increase(grpc_server_handled_total{grpc_method=~"SSHReceivePack|PostReceivePack"}[7d])))'
  PROXY_REMOTE_REQUESTS_EVENT_COUNT_WEEKLY_QUERY = 'round(sum(increase(gitlab_workhorse_http_geo_proxied_requests_total[7d])))'
  PROXY_LOCAL_REQUESTS_EVENT_COUNT_WEEKLY_QUERY = 'round(sum(increase(gitlab_workhorse_http_requests_total{route!="^/-/(readiness|liveness)$"}[7d])))'

  # Eventually, we'll find a way to auto-load this
  # from the metric yaml files that include something
  # like `run_on_secondary: true`, but for now we'll
  # just enumerate them.
  PAYLOAD_COUNT_FIELDS = %w[
    git_fetch_event_count_weekly
    git_push_event_count_weekly
    proxy_remote_requests_event_count_weekly
    proxy_local_requests_event_count_weekly
  ].freeze

  store_accessor :payload, *PAYLOAD_COUNT_FIELDS
  validate :payload_schema_is_valid

  def payload_schema_is_valid
    payload.keys.each do |key|
      if PAYLOAD_COUNT_FIELDS.include?(key)
        errors.add(:payload, "payload[#{key}] must be a number") unless payload[key].nil? || payload[key].is_a?(Numeric)
      else
        errors.add(:payload, "unexpected key in payload - #{key}")
      end
    end
  end

  def self.update_metrics!
    usage_data = new
    usage_data.collect_prometheus_metrics
    usage_data.save!
  end

  def collect_prometheus_metrics
    with_prometheus_client(fallback: nil, verify: false) do |client|
      self.git_fetch_event_count_weekly = client.query(GIT_FETCH_EVENT_COUNT_WEEKLY_QUERY).dig(0, "value", 1)&.to_i
      self.git_push_event_count_weekly = client.query(GIT_PUSH_EVENT_COUNT_WEEKLY_QUERY).dig(0, "value", 1)&.to_i
      self.proxy_remote_requests_event_count_weekly = client.query(PROXY_REMOTE_REQUESTS_EVENT_COUNT_WEEKLY_QUERY).dig(0, "value", 1)&.to_i
      self.proxy_local_requests_event_count_weekly = client.query(PROXY_LOCAL_REQUESTS_EVENT_COUNT_WEEKLY_QUERY).dig(0, "value", 1)&.to_i
    end
  end
end
