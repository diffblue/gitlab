# frozen_string_literal: true

require_relative '../../../fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::Input::Factory, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let(:namespace) { "namespace" }
  let(:agent) { instance_double("Clusters::Agent", id: 1) }
  let(:user) { instance_double("User", name: "name", email: "name@example.com") }
  let(:workspace) { instance_double("RemoteDevelopment::Workspace", id: 1, name: "name", namespace: namespace) }

  let(:workspace_agent_info_hash) do
    create_workspace_agent_info_hash(
      workspace_id: workspace.id,
      workspace_name: workspace.name,
      workspace_namespace: namespace,
      agent_id: agent.id,
      owning_inventory: "#{workspace.name}-workspace-inventory",
      resource_version: "1",
      previous_actual_state: previous_actual_state,
      current_actual_state: current_actual_state,
      workspace_exists: false,
      user_name: user.name,
      user_email: user.email
    )
  end

  let(:expected_namespace) { workspace.namespace }
  let(:expected_deployment_resource_version) { "1" }

  let(:expected_agent_info) do
    ::RemoteDevelopment::Workspaces::Reconcile::Input::AgentInfo.new(
      name: workspace.name,
      namespace: expected_namespace,
      actual_state: current_actual_state,
      deployment_resource_version: expected_deployment_resource_version
    )
  end

  subject do
    described_class.build(agent_info_hash_from_params: workspace_agent_info_hash)
  end

  before do
    allow_next_instance_of(::RemoteDevelopment::Workspaces::Reconcile::Input::ActualStateCalculator) do |instance|
      # rubocop:disable RSpec/ExpectInHook
      expect(instance).to receive(:calculate_actual_state).with(
        latest_k8s_deployment_info: workspace_agent_info_hash[:latest_k8s_deployment_info],
        termination_progress: termination_progress,
        latest_error_details: nil
      ) { current_actual_state }
      # rubocop:enable RSpec/ExpectInHook
    end
  end

  describe '#build' do
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
      let(:expected_deployment_resource_version) { nil }
      let(:termination_progress) do
        RemoteDevelopment::Workspaces::Reconcile::Input::ActualStateCalculator::TERMINATING
      end

      it 'returns an AgentInfo object without deployment_resource_version populated' do
        expect(subject).to eq(expected_agent_info)
      end
    end

    context 'when current actual state is Terminated' do
      let(:previous_actual_state) { ::RemoteDevelopment::Workspaces::States::TERMINATING }
      let(:current_actual_state) { ::RemoteDevelopment::Workspaces::States::TERMINATED }
      let(:expected_deployment_resource_version) { nil }
      let(:termination_progress) do
        RemoteDevelopment::Workspaces::Reconcile::Input::ActualStateCalculator::TERMINATED
      end

      it 'returns an AgentInfo object without deployment_resource_version populated' do
        expect(subject).to eq(expected_agent_info)
      end
    end

    # TODO: Should this case even be possible? See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126127#note_1492911475
    context "when namespace is missing in the payload" do
      let(:previous_actual_state) { ::RemoteDevelopment::Workspaces::States::STARTING }
      let(:current_actual_state) { ::RemoteDevelopment::Workspaces::States::RUNNING }
      let(:termination_progress) { nil }
      let(:namespace) { nil }
      let(:expected_namespace) { nil }

      it 'returns an AgentInfo object without namespace populated' do
        expect(subject).to eq(expected_agent_info)
      end
    end
  end
end
