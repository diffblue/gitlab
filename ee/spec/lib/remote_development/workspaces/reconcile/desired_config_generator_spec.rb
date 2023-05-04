# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::DesiredConfigGenerator, :freeze_time, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  describe '#generate_desired_config' do
    let_it_be(:user) { create(:user) }
    let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
    let(:desired_state) { RemoteDevelopment::Workspaces::States::RUNNING }
    let(:actual_state) { RemoteDevelopment::Workspaces::States::STOPPED }
    let(:deployment_resource_version_from_agent) { workspace.deployment_resource_version }
    let(:owning_inventory) { "#{workspace.name}-workspace-inventory" }

    let(:workspace) do
      create(
        :workspace, agent: agent, user: user,
        desired_state: desired_state, actual_state: actual_state
      )
    end

    let(:expected_config) do
      YAML.load_stream(
        create_config_to_apply(
          workspace_id: workspace.id,
          workspace_name: workspace.name,
          workspace_namespace: workspace.namespace,
          agent_id: workspace.agent.id,
          owning_inventory: owning_inventory,
          started: started,
          user_name: user.name,
          user_email: user.email
        )
      )
    end

    subject do
      described_class.new
    end

    context 'when desired_state results in started=true' do
      let(:started) { true }

      it 'returns expected config' do
        workspace_resources = subject.generate_desired_config(workspace: workspace)

        expect(workspace_resources).to eq(expected_config)
      end
    end

    context 'when desired_state results in started=false' do
      let(:desired_state) { RemoteDevelopment::Workspaces::States::STOPPED }
      let(:started) { false }

      it 'returns expected config' do
        workspace_resources = subject.generate_desired_config(workspace: workspace)

        expect(workspace_resources).to eq(expected_config)
      end
    end
  end
end
