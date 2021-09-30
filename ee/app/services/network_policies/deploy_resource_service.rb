# frozen_string_literal: true

module NetworkPolicies
  class DeployResourceService
    include NetworkPolicies::Responses
    include NetworkPolicies::Types

    def initialize(manifest:, environment:, resource_name: nil, enabled: nil)
      @has_cilium_policy = cilium_policy?(manifest)
      @policy = policy_from_manifest(manifest)
      unless enabled.nil?
        enabled ? policy.enable : policy.disable
      end

      @platform = environment.deployment_platform
      @kubernetes_namespace = environment.deployment_namespace
      @resource_name = resource_name
    end

    def execute
      return empty_resource_response unless policy
      return no_platform_response unless platform

      setup_resource
      deploy_resource
      load_policy_from_resource
      ServiceResponse.success(payload: policy)
    rescue Kubeclient::HttpError => e
      kubernetes_error_response(e.message)
    end

    private

    attr_reader :platform, :policy, :resource_name, :resource, :kubernetes_namespace, :has_cilium_policy

    def setup_resource
      @resource = policy.generate
      resource[:metadata][:namespace] = kubernetes_namespace
    end

    def load_policy_from_resource
      @policy = if has_cilium_policy
                  Gitlab::Kubernetes::CiliumNetworkPolicy.from_resource(resource)
                else
                  Gitlab::Kubernetes::NetworkPolicy.from_resource(resource)
                end
    end

    def deploy_resource
      @resource = if has_cilium_policy
                    deploy_cilium_network_policy
                  else
                    deploy_network_policy
                  end
    end

    def deploy_cilium_network_policy
      return platform.kubeclient.create_cilium_network_policy(resource) unless resource_name

      if resource_name != resource.dig(:metadata, :name)
        platform.kubeclient.delete_cilium_network_policy(resource_name, kubernetes_namespace)
        resource[:metadata][:resourceVersion] = nil
        platform.kubeclient.create_cilium_network_policy(resource)
      else
        platform.kubeclient.update_cilium_network_policy(resource)
      end
    end

    def deploy_network_policy
      return platform.kubeclient.create_network_policy(resource) unless resource_name

      if resource_name != resource.dig(:metadata, :name)
        platform.kubeclient.delete_network_policy(resource_name, kubernetes_namespace)
        resource[:metadata][:resourceVersion] = nil
        platform.kubeclient.create_network_policy(resource)
      else
        platform.kubeclient.update_network_policy(resource)
      end
    end
  end
end
