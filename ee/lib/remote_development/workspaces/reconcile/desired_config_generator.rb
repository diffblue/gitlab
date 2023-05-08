# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      # noinspection RubyResolve
      class DesiredConfigGenerator
        include States

        def generate_desired_config(workspace:)
          name = workspace.name
          namespace = workspace.namespace
          agent = workspace.agent
          desired_state = workspace.desired_state

          domain_template = "{{.port}}-#{name}.#{workspace.dns_zone}"

          workspace_inventory_config_map, owning_inventory =
            create_workspace_inventory_config_map(name: name, namespace: namespace, agent_id: agent.id)
          replicas = get_workspace_replicas(desired_state: desired_state)
          labels, annotations = get_labels_and_annotations(
            agent_id: agent.id,
            owning_inventory: owning_inventory,
            domain_template: domain_template,
            workspace_id: workspace.id
          )

          # TODO: https://gitlab.com/groups/gitlab-org/-/epics/10461 - handle error
          workspace_resources = DevfileParser.new.get_all(
            processed_devfile: workspace.processed_devfile,
            name: name,
            namespace: namespace,
            replicas: replicas,
            domain_template: domain_template,
            labels: labels,
            annotations: annotations
          )
          workspace_resources.insert(0, workspace_inventory_config_map)

          workspace_resources
        end

        private

        def get_workspace_replicas(desired_state:)
          return 1 if [
            CREATION_REQUESTED,
            RUNNING
          ].include?(desired_state)

          0
        end

        # noinspection RubyInstanceMethodNamingConvention
        def create_workspace_inventory_config_map(name:, namespace:, agent_id:)
          owning_inventory = "#{name}-workspace-inventory"
          workspace_inventory_config_map = {
            kind: 'ConfigMap',
            apiVersion: 'v1',
            metadata: {
              name: owning_inventory,
              namespace: namespace,
              labels: {
                'cli-utils.sigs.k8s.io/inventory-id': owning_inventory,
                'agent.gitlab.com/id': agent_id.to_s
              }
            }
          }.deep_stringify_keys
          [workspace_inventory_config_map, owning_inventory]
        end

        def get_labels_and_annotations(agent_id:, owning_inventory:, domain_template:, workspace_id:)
          labels = {
            'agent.gitlab.com/id' => agent_id.to_s
          }
          annotations = {
            'config.k8s.io/owning-inventory' => owning_inventory.to_s,
            'workspaces.gitlab.com/host-template' => domain_template.to_s,
            'workspaces.gitlab.com/id' => workspace_id.to_s
          }
          [labels, annotations]
        end
      end
    end
  end
end
