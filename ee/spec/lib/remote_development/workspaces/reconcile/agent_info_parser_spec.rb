# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::AgentInfoParser, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let(:workspace) { create(:workspace) }

  let(:workspace_agent_info) do
    create_workspace_agent_info(
      workspace_id: workspace.id,
      workspace_name: workspace.name,
      workspace_namespace: workspace.namespace,
      agent_id: workspace.agent.id,
      owning_inventory: "#{workspace.name}-workspace-inventory",
      resource_version: '1',
      previous_actual_state: previous_actual_state,
      current_actual_state: current_actual_state,
      workspace_exists: false
    )
  end

  let(:expected_namespace) { workspace.namespace }
  let(:expected_deployment_resource_version) { '1' }

  let(:expected_agent_info) do
    ::RemoteDevelopment::Workspaces::Reconcile::AgentInfo.new(
      name: workspace.name,
      namespace: expected_namespace,
      actual_state: current_actual_state,
      deployment_resource_version: expected_deployment_resource_version
    )
  end

  subject do
    described_class.new.parse(workspace_agent_info: workspace_agent_info)
  end

  before do
    allow_next_instance_of(::RemoteDevelopment::Workspaces::Reconcile::ActualStateCalculator) do |instance|
      # rubocop:disable RSpec/ExpectInHook
      expect(instance).to receive(:calculate_actual_state).with(
        latest_k8s_deployment_info: workspace_agent_info['latest_k8s_deployment_info'],
        termination_progress: termination_progress
      ) { current_actual_state }
      # rubocop:enable RSpec/ExpectInHook
    end
  end

  describe '#parse' do
    context 'when current actual state is not Terminated or Unknown' do
      let(:previous_actual_state) { ::RemoteDevelopment::Workspaces::States::STARTING }
      let(:current_actual_state) { ::RemoteDevelopment::Workspaces::States::RUNNING }
      let(:termination_progress) { nil }

      it 'returns an AgentInfo object with namespace and deployment_resource_version populated' do
        expect(subject).to eq(expected_agent_info)
      end
    end

    context 'when current actual state is Terminating' do
      let(:previous_actual_state) { ::RemoteDevelopment::Workspaces::States::RUNNING }
      let(:current_actual_state) { ::RemoteDevelopment::Workspaces::States::TERMINATING }
      let(:termination_progress) { RemoteDevelopment::Workspaces::Reconcile::ActualStateCalculator::TERMINATING }
      let(:expected_namespace) { nil }
      let(:expected_deployment_resource_version) { nil }

      it 'returns an AgentInfo object without namespace and deployment_resource_version populated' do
        expect(subject).to eq(expected_agent_info)
      end
    end

    context 'when current actual state is Terminated' do
      let(:previous_actual_state) { ::RemoteDevelopment::Workspaces::States::TERMINATING }
      let(:current_actual_state) { ::RemoteDevelopment::Workspaces::States::TERMINATED }
      let(:termination_progress) { RemoteDevelopment::Workspaces::Reconcile::ActualStateCalculator::TERMINATED }
      let(:expected_namespace) { nil }
      let(:expected_deployment_resource_version) { nil }

      it 'returns an AgentInfo object without namespace and deployment_resource_version populated' do
        expect(subject).to eq(expected_agent_info)
      end
    end
  end
end
