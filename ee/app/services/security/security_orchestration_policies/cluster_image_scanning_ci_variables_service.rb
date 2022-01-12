# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ClusterImageScanningCiVariablesService < ::BaseProjectService
      SCAN_VARIABLES = {
        'CLUSTER_IMAGE_SCANNING_DISABLED' => nil
      }.freeze

      def execute(action)
        # TODO: Add support for multiple clusters. As for now, we only support the first cluster defined in the policy.
        cluster_name, resource_filters = action[:clusters]&.first

        [scan_variables(resource_filters), hidden_variable_attributes(cluster_name.to_s)]
      end

      private

      def scan_variables(resource_filters)
        return SCAN_VARIABLES if resource_filters.blank?

        SCAN_VARIABLES.merge({
          'CIS_CONTAINER_NAMES' => resource_filter_value(resource_filters[:containers]),
          'CIS_RESOURCE_NAMES' => resource_filter_value(resource_filters[:resources]),
          'CIS_RESOURCE_NAMESPACES' => resource_filter_value(resource_filters[:namespaces]),
          'CIS_RESOURCE_KINDS' => resource_filter_value(resource_filters[:kinds])
        }.compact)
      end

      def hidden_variable_attributes(cluster_name)
        cluster = project.all_clusters.enabled.with_name(cluster_name).first
        return {} if cluster.blank?

        deployment_platform = cluster.platform_kubernetes
        return {} if deployment_platform.blank?

        kubeconfig = deployment_platform.kubeconfig(Clusters::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAMESPACE)

        [{ key: 'CIS_KUBECONFIG', value: kubeconfig, variable_type: :file }]
      end

      def resource_filter_value(filter_values)
        return if filter_values.blank?

        filter_values.compact.join(",")
      end
    end
  end
end
