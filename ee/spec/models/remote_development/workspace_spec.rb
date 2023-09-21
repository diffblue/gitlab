# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspace, feature_category: :remote_development do
  let_it_be(:user) { create(:user) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let_it_be(:project) { create(:project, :in_group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  subject do
    create(:workspace, user: user, agent: agent, project: project, personal_access_token: personal_access_token)
  end

  describe 'associations' do
    context "for has_one" do
      it { is_expected.to have_one(:remote_development_agent_config) }
    end

    context "for has_many" do
      it { is_expected.to have_many(:workspace_variables) }
    end

    context "for belongs_to" do
      it { is_expected.to belong_to(:user) }
      it { is_expected.to belong_to(:personal_access_token) }

      it do
        is_expected
          .to belong_to(:agent)
                .class_name('Clusters::Agent')
                .with_foreign_key(:cluster_agent_id)
                .inverse_of(:workspaces)
      end
    end

    context "when from factory" do
      it 'has correct associations from factory' do
        expect(subject.user).to eq(user)
        expect(subject.project).to eq(project)
        expect(subject.agent).to eq(agent)
        expect(subject.personal_access_token).to eq(personal_access_token)
        expect(subject.remote_development_agent_config).to eq(agent.remote_development_agent_config)
        expect(agent.remote_development_agent_config.workspaces.first).to eq(subject)
        expect(subject.url).to eq("https://60001-#{subject.name}.#{agent.remote_development_agent_config.dns_zone}")
      end
    end
  end

  describe '#terminated?' do
    let(:actual_state) { ::RemoteDevelopment::Workspaces::States::TERMINATED }

    subject { build(:workspace, actual_state: actual_state) }

    it 'returns true if terminated' do
      expect(subject.terminated?).to eq(true)
    end
  end

  describe '.before_save' do
    describe 'when creating new record', :freeze_time do
      # NOTE: The workspaces factory overrides the desired_state_updated_at to be earlier than
      #       the current time, so we need to use build here instead of create here to test
      #       the callback which sets the desired_state_updated_at to current time upon creation.
      subject { build(:workspace, user: user, agent: agent, project: project) }

      it 'sets desired_state_updated_at' do
        subject.save!
        # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
        expect(subject.desired_state_updated_at).to eq(Time.current)
      end
    end

    describe 'when updating desired_state' do
      it 'sets desired_state_updated_at' do
        expect { subject.update!(desired_state: ::RemoteDevelopment::Workspaces::States::RUNNING) }.to change {
          # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
          subject.desired_state_updated_at
        }
      end
    end

    describe 'when updating a field other than desired_state' do
      it 'does not set desired_state_updated_at' do
        expect { subject.update!(actual_state: ::RemoteDevelopment::Workspaces::States::RUNNING) }.not_to change {
          # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
          subject.desired_state_updated_at
        }
      end
    end
  end

  describe 'validations' do
    # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
    it 'validates max_hours_before_termination is no more than 120' do
      subject.max_hours_before_termination = described_class::MAX_HOURS_BEFORE_TERMINATION_LIMIT
      expect(subject).to be_valid

      subject.max_hours_before_termination = described_class::MAX_HOURS_BEFORE_TERMINATION_LIMIT + 1
      expect(subject).not_to be_valid
    end

    it 'validates editor is webide' do
      subject.editor = 'not-webide'
      expect(subject).not_to be_valid
    end

    context 'on remote_development_agent_config' do
      let(:agent_with_no_remote_development_config) { create(:cluster_agent) }

      subject do
        build(:workspace, user: user, url: "URL", agent: agent_with_no_remote_development_config, project: project)
      end

      it 'validates presence of agent.remote_development_agent_config' do
        # sanity check of fixture
        expect(agent_with_no_remote_development_config.remote_development_agent_config).not_to be_present

        expect(subject).not_to be_valid
        expect(subject.errors[:agent]).to include('for Workspace must have an associated RemoteDevelopmentAgentConfig')
      end
    end
  end

  describe 'scopes' do
    describe '.without_terminated' do
      let(:actual_and_desired_state_running_workspace) do
        create(
          :workspace,
          actual_state: RemoteDevelopment::Workspaces::States::RUNNING,
          desired_state: RemoteDevelopment::Workspaces::States::RUNNING
        )
      end

      let(:desired_state_terminated_workspace) do
        create(:workspace, desired_state: RemoteDevelopment::Workspaces::States::TERMINATED)
      end

      let(:actual_state_terminated_workspace) do
        create(:workspace, actual_state: RemoteDevelopment::Workspaces::States::TERMINATED)
      end

      let(:actual_and_desired_state_terminated_workspace) do
        create(
          :workspace,
          actual_state: RemoteDevelopment::Workspaces::States::TERMINATED,
          desired_state: RemoteDevelopment::Workspaces::States::TERMINATED
        )
      end

      it 'returns workspaces who do not have desired_state and actual_state as Terminated' do
        subject
        expect(described_class.without_terminated).to include(actual_and_desired_state_running_workspace)
        expect(described_class.without_terminated).to include(desired_state_terminated_workspace)
        expect(described_class.without_terminated).to include(actual_state_terminated_workspace)
        expect(described_class.without_terminated).not_to include(actual_and_desired_state_terminated_workspace)
      end
    end
  end
end
