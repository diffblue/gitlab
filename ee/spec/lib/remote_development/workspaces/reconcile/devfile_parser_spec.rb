# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::DevfileParser, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let_it_be(:user) { create(:user) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let_it_be(:workspace) { create(:workspace, agent: agent, user: user) }
  let(:owning_inventory) { "#{workspace.name}-workspace-inventory" }

  let(:domain_template) { "{{.port}}-#{workspace.name}.#{workspace.dns_zone}" }

  describe '#get_all' do
    let(:expected_workspace_resources) do
      YAML.load_stream(
        create_config_to_apply(
          workspace_id: workspace.id,
          workspace_name: workspace.name,
          workspace_namespace: workspace.namespace,
          agent_id: workspace.agent.id,
          owning_inventory: owning_inventory,
          started: true,
          include_inventory: false
        )
      )
    end

    subject do
      described_class.new
    end

    it 'returns workspace_resources' do
      workspace_resources = subject.get_all(
        processed_devfile: example_processed_devfile,
        name: workspace.name,
        namespace: workspace.namespace,
        replicas: 1,
        domain_template: domain_template,
        labels: { 'agent.gitlab.com/id' => workspace.agent.id },
        annotations: {
          'config.k8s.io/owning-inventory' => owning_inventory,
          'workspaces.gitlab.com/host-template' => domain_template,
          'workspaces.gitlab.com/id' => workspace.id
        }
      )

      # noinspection RubyResolve
      expect(workspace_resources).to eq(expected_workspace_resources)
    end
  end
end
