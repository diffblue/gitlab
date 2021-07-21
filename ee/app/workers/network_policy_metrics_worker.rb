# frozen_string_literal: true

# While we are trying to minimise impact of restarts by only having
# side-effect at the end of the job we can not make this worker truly
# idempotent because of the additive nature of the underlying redis counter.
class NetworkPolicyMetricsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  queue_namespace :cronjob
  feature_category :container_network_security

  def perform
    services = ::Integrations::Prometheus
                 .preload_project
                 .with_clusters_with_cilium
    service_metrics = count_adapter_metrics(services)

    cluster_apps = Clusters::Applications::Prometheus
                     .preload_cluster_platform
                     .with_clusters_with_cilium
    cluster_app_metrics = count_adapter_metrics(cluster_apps)

    Gitlab::UsageDataCounters::NetworkPolicyCounter.add(
      service_metrics[:forwards] + cluster_app_metrics[:forwards],
      service_metrics[:drops] + cluster_app_metrics[:drops]
    )
  end

  private

  def count_adapter_metrics(relation)
    acc = { forwards: 0, drops: 0 }
    relation.find_each do |adapter|
      next unless adapter.configured?

      begin
        result = Gitlab::Prometheus::Queries::PacketFlowMetricsQuery.new(adapter.prometheus_client).query
        acc[:forwards] += result[:forwards]
        acc[:drops] += result[:drops]
      rescue Gitlab::PrometheusClient::Error
        next
      end
    end
    acc
  end
end
