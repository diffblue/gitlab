# frozen_string_literal: true

module Geo
  class MetricsUpdateService
    METRIC_PREFIX = 'geo_'

    def execute
      return unless Gitlab::Geo.enabled?

      current_node_status&.update_cache!

      send_status_to_primary(current_node, current_node_status) if Gitlab::Geo.secondary?

      if prometheus_enabled?
        update_prometheus_metrics(current_node, current_node_status)

        if Gitlab::Geo.primary?
          Gitlab::Geo.secondary_nodes.find_each { |node| update_prometheus_metrics(node, node.status) }
        end
      end
    end

    private

    def current_node_status
      @current_node_status ||= GeoNodeStatus.current_node_status
    end

    def current_node
      Gitlab::Geo.current_node
    end

    def send_status_to_primary(node, status)
      if !NodeStatusRequestService.new(status).execute && prometheus_enabled?
        increment_failed_status_counter(node)
      end
    end

    def update_prometheus_metrics(node, status)
      return unless node&.enabled?

      return unless status

      GeoNodeStatus::PROMETHEUS_METRICS.each do |column, docstring|
        value = status[column]

        next unless value.is_a?(Integer)

        gauge = Gitlab::Metrics.gauge(gauge_metric_name(column), docstring, {}, :max)
        gauge.set(metric_labels(node), value)
      end
    end

    def increment_failed_status_counter(node)
      failed_status_counter(node).increment
    end

    def failed_status_counter(node)
      Gitlab::Metrics.counter(
        :geo_status_failed_total,
        'Total number of times status for Geo node failed to be sent to the primary',
        metric_labels(node))
    end

    def gauge_metric_name(name)
      # Prometheus naming conventions in
      # https://prometheus.io/docs/instrumenting/writing_exporters/#naming says
      # that _count and _total should be reserved for counters
      base_name = name.to_s.gsub(/(_count|_total)$/, '')

      (METRIC_PREFIX + base_name).to_sym
    end

    def metric_labels(node)
      labels = { name: node.name }

      # Installations that existed before 11.11 were using the `url` label. This
      # line preserves continuity of metrics.
      #
      # This can be removed in 12.0+ since there will have been at least one
      # release worth of data labeled with `name`.
      labels[:url] = node.name

      labels
    end

    def prometheus_enabled?
      Gitlab::Metrics.prometheus_metrics_enabled?
    end
  end
end
