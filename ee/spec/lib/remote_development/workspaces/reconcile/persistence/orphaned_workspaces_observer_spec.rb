# frozen_string_literal: true

require_relative '../../../fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::Persistence::OrphanedWorkspacesObserver, feature_category: :remote_development do
  let(:agent) { instance_double("Clusters::Agent", id: 1) }
  let(:update_type) { RemoteDevelopment::Workspaces::Reconcile::UpdateTypes::PARTIAL }
  let(:logger) { instance_double(::Logger) }

  let(:workspace) { instance_double("RemoteDevelopment::Workspace", name: "name", namespace: "namespace") }

  let(:persisted_workspace_agent_info) do
    RemoteDevelopment::Workspaces::Reconcile::Input::AgentInfo.new(
      name: workspace.name,
      namespace: workspace.namespace,
      actual_state: RemoteDevelopment::Workspaces::States::STOPPED,
      deployment_resource_version: "1"
    )
  end

  let(:orphaned_workspace_agent_info) do
    RemoteDevelopment::Workspaces::Reconcile::Input::AgentInfo.new(
      name: "orphaned_workspace",
      namespace: "orphaned_workspace_namespace",
      actual_state: RemoteDevelopment::Workspaces::States::RUNNING,
      deployment_resource_version: "1"
    )
  end

  let(:workspaces_from_agent_infos) { [workspace] }

  let(:value) do
    {
      agent: agent,
      update_type: update_type,
      workspace_agent_infos_by_name: workspace_agent_infos_by_name,
      workspaces_from_agent_infos: workspaces_from_agent_infos,
      logger: logger
    }
  end

  subject do
    described_class.observe(value)
  end

  context "when orphaned workspaces exist" do
    let(:workspace_agent_infos_by_name) do
      {
        persisted_workspace_agent_info.name => persisted_workspace_agent_info,
        orphaned_workspace_agent_info.name => orphaned_workspace_agent_info
      }.symbolize_keys
    end

    it "logs orphaned workspaces at warn level", :unlimited_max_formatted_output_length do
      expect(logger).to receive(:warn).with(
        message: "Received orphaned workspace agent info for workspace(s) where no persisted workspace record exists",
        error_type: "orphaned_workspace",
        agent_id: agent.id,
        update_type: update_type,
        count: 1,
        orphaned_workspaces: [
          {
            name: orphaned_workspace_agent_info.name,
            namespace: orphaned_workspace_agent_info.namespace,
            actual_state: orphaned_workspace_agent_info.actual_state
          }
        ]
      )

      expect(subject).to eq(value)
    end
  end

  context "when no orphaned workspaces exist" do
    let(:workspace_agent_infos_by_name) do
      {
        persisted_workspace_agent_info.name => persisted_workspace_agent_info
      }.symbolize_keys
    end

    it "does not log" do
      expect(logger).not_to receive(:warn)

      expect(subject).to eq(value)
    end
  end
end
