# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      class AgentInfoParser
        # @param [Hash] workspace_agent_info
        # @return [RemoteDevelopment::Workspaces::Reconcile::AgentInfo]
        def parse(workspace_agent_info:)
          # workspace_agent_info.fetch('latest_k8s_deployment_info') is not used since the field may not be present
          latest_k8s_deployment_info = workspace_agent_info['latest_k8s_deployment_info']

          actual_state = ActualStateCalculator.new.calculate_actual_state(
            latest_k8s_deployment_info: latest_k8s_deployment_info,
            # workspace_agent_info.fetch('termination_progress') is not used since the field may not be present
            termination_progress: workspace_agent_info['termination_progress'],
            latest_error_details: workspace_agent_info['error_details']
          )

          deployment_resource_version = latest_k8s_deployment_info&.dig('metadata', 'resourceVersion')

          # If the actual state of the workspace is Terminated, the only keys which will be put into the
          # AgentInfo object are name, namespace and actual_state
          info = {
            name: workspace_agent_info.fetch('name'),
            actual_state: actual_state,
            namespace: workspace_agent_info.fetch('namespace'),
            deployment_resource_version: deployment_resource_version
          }

          AgentInfo.new(**info)
        end
      end
    end
  end
end
