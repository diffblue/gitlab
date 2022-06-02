# frozen_string_literal: true

module EE
  module Clusters
    module ClusterPresenter
      extend ::Gitlab::Utils::Override

      override :health_data
      def health_data(clusterable)
        super.merge(
          'metrics-endpoint': clusterable.metrics_cluster_path(cluster, format: :json)
        )
      end
    end
  end
end
