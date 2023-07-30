# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::Persistence::WorkspacesFromAgentInfosUpdater, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let_it_be(:user) { create(:user) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }

  let(:desired_state) { RemoteDevelopment::Workspaces::States::RUNNING }
  let(:actual_state) { RemoteDevelopment::Workspaces::States::STARTING }

  let(:workspace) do
    create(
      :workspace,
      agent: agent,
      user: user,
      desired_state: desired_state,
      actual_state: actual_state
    )
  end

  let(:workspace_agent_info) do
    RemoteDevelopment::Workspaces::Reconcile::Input::AgentInfo.new(
      name: workspace.name,
      namespace: workspace.namespace,
      actual_state: actual_state,
      deployment_resource_version: "1"
    )
  end

  let(:workspace_agent_infos_by_name) do
    {
      workspace_agent_info.name => workspace_agent_info
    }.symbolize_keys
  end

  let(:value) do
    {
      agent: agent,
      workspace_agent_infos_by_name: workspace_agent_infos_by_name
    }
  end

  subject do
    described_class.update(value) # rubocop:disable Rails/SaveBang
  end

  it "returns persisted workspaces" do
    expect(subject).to eq(value.merge(workspaces_from_agent_infos: [workspace]))
  end

  context "when persisted workspace desired_state is RESTART_REQUESTED and actual_state is STOPPED" do
    let(:desired_state) { RemoteDevelopment::Workspaces::States::RESTART_REQUESTED }
    let(:actual_state) { RemoteDevelopment::Workspaces::States::STOPPED }

    it "sets persisted workspace desired state to RUNNING" do
      expect(subject).to eq(value.merge(workspaces_from_agent_infos: [workspace]))
      expect(workspace.reload.desired_state).to eq(RemoteDevelopment::Workspaces::States::RUNNING)
    end
  end

  context "when persisted workspace created_at + max_hours_before_termination.hours < Time.current" do
    before do
      workspace.update!(created_at: 2.days.ago, max_hours_before_termination: 1)
    end

    it "sets persisted workspace desired state to TERMINATED" do
      expect(subject).to eq(value.merge(workspaces_from_agent_infos: [workspace]))
      expect(workspace.reload.desired_state).to eq(RemoteDevelopment::Workspaces::States::TERMINATED)
    end
  end
end
