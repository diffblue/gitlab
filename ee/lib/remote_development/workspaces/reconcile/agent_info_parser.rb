# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      class AgentInfoParser
        def parse(workspace_agent_info:)
          # workspace_agent_info.fetch('latest_k8s_deployment_info') is not used since the field may not be present
          latest_k8s_deployment_info = workspace_agent_info['latest_k8s_deployment_info']

          actual_state = ActualStateCalculator.new.calculate_actual_state(
            latest_k8s_deployment_info: latest_k8s_deployment_info,
            # workspace_agent_info.fetch('termination_progress') is not used since the field may not be present
            termination_progress: workspace_agent_info['termination_progress']
          )

          # If the actual state of the workspace is Terminated, the only keys which will be put into the
          # AgentInfo object are name and actual_state
          info = {
            name: workspace_agent_info.fetch('name'),
            namespace: nil,
            actual_state: actual_state,
            deployment_resource_version: nil
          }

          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409778
          #       We probably need to eventually handle States::ERROR and States::FAILURE here too. Will they possibly
          #       be missing the namespace or deployment_resource_version too?
          unless [States::TERMINATING, States::TERMINATED, States::UNKNOWN].include?(actual_state)
            # Unless the workspace is already terminated, the other workspace_agent_info entries should be populated
            info[:namespace] = workspace_agent_info.fetch('namespace')
            deployment_resource_version = latest_k8s_deployment_info.fetch('metadata').fetch('resourceVersion')
            # NOTE: Kubernetes updates the deployment_resource_version every time a new config is applied, even if
            # that config is identical to the currently running configuration and results in no changes.
            info[:deployment_resource_version] = deployment_resource_version
          end

          AgentInfo.new(**info)
        end
      end
    end
  end
end
