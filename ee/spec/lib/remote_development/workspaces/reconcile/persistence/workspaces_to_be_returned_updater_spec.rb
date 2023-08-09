# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::Persistence::WorkspacesToBeReturnedUpdater, feature_category: :remote_development do
  let_it_be(:user) { create(:user) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }

  let_it_be(:workspace1) do
    create(
      :workspace,
      :without_realistic_after_create_timestamp_updates,
      name: "workspace1",
      agent: agent,
      user: user
    )
  end

  let_it_be(:workspace2) do
    create(
      :workspace,
      :without_realistic_after_create_timestamp_updates,
      name: "workspace2",
      agent: agent,
      user: user
    )
  end

  # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
  let(:workspaces_to_be_returned) { [workspace1, workspace2] }

  let(:value) do
    {
      agent: agent,
      workspaces_to_be_returned: workspaces_to_be_returned
    }
  end

  subject do
    described_class.update(value) # rubocop:disable Rails/SaveBang - This is not an ActiveRecord model
  end

  # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
  before do
    workspace1.update_attribute(:responded_to_agent_at, 2.hours.ago)
    workspace2.update_attribute(:responded_to_agent_at, 2.hours.ago)
    agent.reload
  end

  context "with fixture sanity checks" do
    # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
    it "has the expected fixtures" do
      expect(workspace1.responded_to_agent_at).to be < 1.hour.ago
      expect(workspace2.responded_to_agent_at).to be < 1.hour.ago
    end
  end

  context "for update_type FULL" do
    # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
    it "updates all workspaces", :unlimited_max_formatted_output_length do
      subject
      expect(workspace1.reload.responded_to_agent_at).to be > 1.minute.ago
      expect(workspace2.reload.responded_to_agent_at).to be > 1.minute.ago
    end

    # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31543
    it "preserves existing value entries" do
      subject
      expect(subject).to eq(value.merge(workspaces_to_be_returned: [workspace1.reload, workspace2.reload]))
    end
  end
end
