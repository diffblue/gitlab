# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillWorkspacePersonalAccessToken, feature_category: :remote_development do
  describe "#perform" do
    let(:workspace_attrs) do
      {
        user_id: user.id,
        project_id: project.id,
        cluster_agent_id: cluster_agent.id,
        desired_state_updated_at: 2.seconds.ago,
        max_hours_before_termination: 19,
        namespace: 'ns',
        actual_state: ::RemoteDevelopment::Workspaces::States::RUNNING,
        desired_state: ::RemoteDevelopment::Workspaces::States::RUNNING,
        editor: 'e',
        devfile_ref: 'dfr',
        devfile_path: 'dev/path',
        config_version: 1,
        url: 'https://www.example.org'
      }
    end

    let(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
    let(:project) do
      table(:projects).create!(name: 'project', path: 'project', project_namespace_id: namespace.id,
        namespace_id: namespace.id)
    end

    let(:cluster_agent) { table(:cluster_agents).create!(name: 'cluster_agent', project_id: project.id) }
    let(:user) { table(:users).create!(email: 'author@example.com', username: 'author', projects_limit: 10) }
    let(:workspaces_table) { table(:workspaces) }
    let(:personal_access_tokens_table) { table(:personal_access_tokens) }
    let!(:pat) do
      personal_access_tokens_table.create!(name: 'workspace1', user_id: user.id, scopes: "---\n- api\n",
        expires_at: 4.days.from_now)
    end

    let!(:workspace_with_personal_access_token) do
      workspaces_table.create!({
        name: 'workspace2',
        personal_access_token_id: pat.id
      }.merge!(workspace_attrs))
    end

    let(:migration) do
      described_class.new(
        start_id: workspace_with_personal_access_token.id,
        end_id: workspace_with_personal_access_token.id,
        batch_table: :workspaces,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      )
    end

    it "does not modify workspace's existing token" do
      expect { migration.perform }.not_to change {
                                            workspace_with_personal_access_token.reload.personal_access_token_id
                                          }
    end
  end

  describe "#calculate_expires_at" do
    let(:migration) do
      described_class.new(
        start_id: 1,
        end_id: 2,
        batch_table: :workspaces,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      )
    end

    it "calculates the expiration date correctly" do
      created_at = DateTime.parse("2023-09-13 12:00:00")
      max_hours_before_termination = 24

      expected_expires_at = DateTime.parse("2023-09-15")

      result = migration.calculate_expires_at(created_at, max_hours_before_termination)
      expect(result).to eq(expected_expires_at)
    end
  end

  describe "#calculate_revoked" do
    let(:migration) do
      described_class.new(
        start_id: 1,
        end_id: 2,
        batch_table: :workspaces,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      )
    end

    it "returns true if expires_at is in the past" do
      expires_at = DateTime.yesterday
      desired_state = ::RemoteDevelopment::Workspaces::States::RUNNING

      result = migration.calculate_revoked(expires_at, desired_state)
      expect(result).to be(true)
    end

    it "returns true if desired_state is 'Terminated'" do
      expires_at = DateTime.tomorrow
      desired_state = ::RemoteDevelopment::Workspaces::States::TERMINATED

      result = migration.calculate_revoked(expires_at, desired_state)
      expect(result).to be(true)
    end

    it "returns false if expires_at is in the future and desired_state is not 'Terminated'" do
      expires_at = DateTime.tomorrow
      desired_state = ::RemoteDevelopment::Workspaces::States::RUNNING

      result = migration.calculate_revoked(expires_at, desired_state)
      expect(result).to be(false)
    end
  end
end
