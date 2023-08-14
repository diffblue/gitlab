# frozen_string_literal: true

require_relative '../../../fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::Output::DesiredConfigGenerator, :freeze_time, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  describe '#generate_desired_config' do
    let(:logger) { instance_double(Logger) }
    let(:user) { instance_double("User", name: "name", email: "name@example.com") }
    let(:remote_development_agent_config) do
      instance_double(
        "RemoteDevelopment::RemoteDevelopmentAgentConfig",
        network_policy_enabled: network_policy_enabled,
        gitlab_workspaces_proxy_namespace: gitlab_workspaces_proxy_namespace
      )
    end

    let(:agent) do
      instance_double("Clusters::Agent", id: 1, remote_development_agent_config: remote_development_agent_config)
    end

    let(:desired_state) { RemoteDevelopment::Workspaces::States::RUNNING }
    let(:actual_state) { RemoteDevelopment::Workspaces::States::STOPPED }
    let(:deployment_resource_version_from_agent) { workspace.deployment_resource_version }
    let(:network_policy_enabled) { true }
    let(:gitlab_workspaces_proxy_namespace) { 'gitlab-workspaces' }

    let(:workspace) do
      instance_double(
        "RemoteDevelopment::Workspace",
        id: 1,
        name: "name",
        namespace: "namespace",
        deployment_resource_version: "1",
        desired_state: desired_state,
        actual_state: actual_state,
        dns_zone: "workspaces.localdev.me",
        processed_devfile: example_processed_devfile,
        user: user,
        agent: agent
      )
    end

    let(:expected_config) do
      YAML.load_stream(
        create_config_to_apply(
          workspace_id: workspace.id,
          workspace_name: workspace.name,
          workspace_namespace: workspace.namespace,
          agent_id: workspace.agent.id,
          started: started,
          user_name: user.name,
          user_email: user.email,
          include_network_policy: network_policy_enabled
        )
      )
    end

    subject do
      described_class
    end

    context 'when desired_state results in started=true' do
      let(:started) { true }

      it 'returns expected config' do
        workspace_resources = subject.generate_desired_config(workspace: workspace, logger: logger)

        expect(workspace_resources).to eq(expected_config)
      end
    end

    context 'when desired_state results in started=false' do
      let(:desired_state) { RemoteDevelopment::Workspaces::States::STOPPED }
      let(:started) { false }

      it 'returns expected config' do
        workspace_resources = subject.generate_desired_config(workspace: workspace, logger: logger)

        expect(workspace_resources).to eq(expected_config)
      end
    end

    context 'when network policy is disabled for agent' do
      let(:started) { true }
      let(:network_policy_enabled) { false }

      it 'returns expected config without network policy' do
        workspace_resources = subject.generate_desired_config(workspace: workspace, logger: logger)

        expect(workspace_resources).to eq(expected_config)
      end
    end

    context 'when DevfileParser returns empty array' do
      before do
        allow(RemoteDevelopment::Workspaces::Reconcile::Output::DevfileParser).to receive(:get_all).and_return([])
      end

      it 'returns an empty array' do
        workspace_resources = subject.generate_desired_config(workspace: workspace, logger: logger)

        expect(workspace_resources).to eq([])
      end
    end
  end
end
