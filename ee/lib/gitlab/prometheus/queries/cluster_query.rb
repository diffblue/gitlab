# frozen_string_literal: true

module Gitlab
  module Prometheus
    module Queries
      class ClusterQuery < BaseQuery
        include QueryAdditionalMetrics

        def query
          AdditionalMetricsParser.load_groups_from_yaml('queries_cluster_metrics.yml')
            .map(&query_group(base_query_context(8.hours.ago, Time.current)))
        end
      end
    end
  end
end
