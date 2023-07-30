# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::Persistence::WorkspacesToBeReturnedFinder, feature_category: :remote_development do
  let_it_be(:user) { create(:user) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }

  let_it_be(:workspace_only_returned_by_full_update, reload: true) do
    create(
      :workspace,
      :without_realistic_after_create_timestamp_updates,
      name: "workspace_only_returned_by_full_update",
      agent: agent,
      user: user,
      responded_to_agent_at: 2.hours.ago
    )
  end

  let_it_be(:workspace_from_agent_info, reload: true) do
    create(
      :workspace,
      :without_realistic_after_create_timestamp_updates,
      name: "workspace_from_agent_info",
      agent: agent,
      user: user,
      responded_to_agent_at: 2.hours.ago
    )
  end

  let_it_be(:workspace_with_new_update_to_desired_state, reload: true) do
    create(
      :workspace,
      :without_realistic_after_create_timestamp_updates,
      name: "workspace_with_new_update_to_desired_state",
      agent: agent,
      user: user,
      responded_to_agent_at: 2.hours.ago
    )
  end

  # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
  let(:workspaces_from_agent_infos) { [workspace_from_agent_info] }

  let(:value) do
    {
      agent: agent,
      update_type: update_type,
      workspaces_from_agent_infos: workspaces_from_agent_infos
    }
  end

  subject do
    described_class.find(value)
  end

  # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
  before do
    agent.reload

    # desired_state_updated_at IS NOT more recent than responded_to_agent_at
    workspace_only_returned_by_full_update.update_attribute(
      :desired_state_updated_at,
      workspace_only_returned_by_full_update.responded_to_agent_at - 1.hour
    )

    # desired_state_updated_at IS NOT more recent than responded_to_agent_at
    workspace_from_agent_info.update_attribute(
      :desired_state_updated_at,
      workspace_from_agent_info.responded_to_agent_at - 1.hour
    )

    # desired_state_updated_at IS more recent than responded_to_agent_at
    workspace_with_new_update_to_desired_state.update_attribute(
      :desired_state_updated_at,
      workspace_with_new_update_to_desired_state.responded_to_agent_at + 1.hour
    )

    subject
  end

  context "with fixture sanity checks" do
    let(:update_type) { RemoteDevelopment::Workspaces::Reconcile::UpdateTypes::FULL }

    # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
    it "has the expected fixtures" do
      expect(workspace_only_returned_by_full_update.desired_state_updated_at)
        .to be < workspace_only_returned_by_full_update.responded_to_agent_at
      expect(workspace_with_new_update_to_desired_state.desired_state_updated_at)
        .to be > workspace_with_new_update_to_desired_state.responded_to_agent_at
      expect(workspace_from_agent_info.desired_state_updated_at)
        .to be < workspace_from_agent_info.responded_to_agent_at
    end
  end

  context "for update_type FULL" do
    let(:update_type) { RemoteDevelopment::Workspaces::Reconcile::UpdateTypes::FULL }

    # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
    let(:expected_workspaces_to_be_returned) do
      [
        # Includes ALL workspaces including workspace_only_returned_by_full_update
        workspace_only_returned_by_full_update,
        workspace_from_agent_info,
        workspace_with_new_update_to_desired_state
      ]
    end

    it "returns all workspaces" do
      expect(subject.fetch(:workspaces_to_be_returned).map(&:name))
        .to match_array(expected_workspaces_to_be_returned.map(&:name))
      expect(subject).to match(hash_including(value))
    end

    it "preserves existing value entries",
      :unlimited_max_formatted_output_length do
      expect(subject).to eq(value.merge(workspaces_to_be_returned: expected_workspaces_to_be_returned))
    end
  end

  context "for update_type PARTIAL" do
    let(:update_type) { RemoteDevelopment::Workspaces::Reconcile::UpdateTypes::PARTIAL }

    # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
    let(:expected_workspaces_to_be_returned) do
      [
        # Does NOT include workspace_only_returned_by_full_update
        workspace_from_agent_info,
        workspace_with_new_update_to_desired_state
      ]
    end

    it "returns only workspaces with new updates to desired state or in workspaces_from_agent_infos" do
      expect(subject.fetch(:workspaces_to_be_returned).map(&:name))
        .to eq(expected_workspaces_to_be_returned.map(&:name))
    end

    it "preserves existing value entries",
      :unlimited_max_formatted_output_length do
      expect(subject).to eq(value.merge(workspaces_to_be_returned: expected_workspaces_to_be_returned))
    end
  end
end
