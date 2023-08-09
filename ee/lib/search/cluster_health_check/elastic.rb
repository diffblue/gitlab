# frozen_string_literal: true

module Search
  module ClusterHealthCheck
    class Elastic
      include ::Gitlab::Loggable

      CACHE_TIMEOUT = 5.minutes
      DEFAULT_UTILIZATION = 0
      HEAP_FACTOR = 0.8
      HEAP_THRESHOLD = 90
      LOAD_FACTOR = 1
      LOAD_THRESHOLD = 15
      NODE_LIMIT = 5

      class << self
        def instance
          @instance ||= new
        end

        delegate :healthy?, :cached_metrics, :non_cached_metrics, :utilization, to: :instance
      end

      def healthy?
        metrics = cached_metrics

        return false unless metrics

        log_utilization(metrics) if Feature.enabled?(:log_advanced_search_cluster_health_elastic)

        !metrics[:cluster_status_red]
      end

      def log_utilization(metrics)
        logger.info(build_structured_payload(**{ message: 'Utilization metrics' }.merge(metrics)))
      end

      def cached_metrics
        Rails.cache.fetch([self.class.name, :metrics], expires_in: CACHE_TIMEOUT) do
          non_cached_metrics
        end
      end

      def non_cached_metrics
        {
          utilization: utilization,
          cluster_status_red: cluster_status_red?,
          load_average: avg_load_average,
          heap_usage: avg_heap_used
        }
      rescue StandardError => e
        logger.warn(e.message)
        nil
      end

      def cluster_status_red?
        client.cluster.health['status'] == 'red'
      end

      def utilization
        ((load_utilization * LOAD_FACTOR) + (heap_utilization * HEAP_FACTOR)).round(3).clamp(0, 100)
      end

      def load_utilization
        load_average = avg_load_average
        ((load_average / (load_average + LOAD_THRESHOLD)) * 100).clamp(0, 100)
      end

      def heap_utilization
        heap_usage = avg_heap_used
        ((heap_usage / (heap_usage + HEAP_THRESHOLD)) * 100).clamp(0, 100)
      end

      def avg_load_average
        highest_load_averages = node_load_averages.max(NODE_LIMIT)
        average(highest_load_averages).clamp(0, 100)
      end

      def avg_heap_used
        highest_heap_used_percentages = node_heap_used_percentages.max(NODE_LIMIT)
        average(highest_heap_used_percentages).clamp(0, 100)
      end

      def node_load_averages
        node_stats.map { |node| node.last['os']['cpu']['load_average']['1m'] }
      end

      def node_heap_used_percentages
        node_stats.map { |node| node.last['jvm']['mem']['heap_used_percent'] }
      end

      def average(array)
        array.sum.fdiv(array.size)
      end

      def client
        @client ||= Gitlab::Elastic::Helper.default.client
      end

      def node_stats
        @node_stats ||= client.nodes.stats(metric: %w[os jvm])['nodes']
      end

      def logger
        @logger ||= ::Gitlab::Elasticsearch::Logger.build
      end
    end
  end
end
