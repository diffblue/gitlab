# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspace, feature_category: :remote_development do
  let_it_be(:user) { create(:user) }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let_it_be(:project) { create(:project, :public, :in_group) }

  subject { create(:workspace, user: user, agent: agent, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_one(:remote_development_agent_config) }

    # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409786
    #       This expectation no longer works after the introduction of RemoteDevelopmentAgentConfig, don't know why.
    # it { is_expected.to belong_to(:agent).with_foreign_key('cluster_agent_id').class_name('Clusters::Agent') }

    it 'has correct associations from factory' do
      expect(subject.user).to eq(user)
      expect(subject.project).to eq(project)
      expect(subject.agent).to eq(agent)
      expect(subject.remote_development_agent_config).to eq(agent.remote_development_agent_config)
      expect(agent.remote_development_agent_config.workspaces.first).to eq(subject)
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
        # noinspection RubyResolve
        expect(subject.desired_state_updated_at).to eq(Time.current)
      end
    end

    describe 'when updating desired_state' do
      it 'sets desired_state_updated_at' do
        expect { subject.update!(desired_state: ::RemoteDevelopment::Workspaces::States::RUNNING) }.to change {
          # noinspection RubyResolve
          subject.desired_state_updated_at
        }
      end
    end

    describe 'when updating a field other than desired_state' do
      it 'does not set desired_state_updated_at' do
        expect { subject.update!(actual_state: ::RemoteDevelopment::Workspaces::States::RUNNING) }.not_to change {
          # noinspection RubyResolve
          subject.desired_state_updated_at
        }
      end
    end
  end

  describe 'validations' do
    it 'validates max_hours_before_termination is no more than 120' do
      # noinspection RubyResolve
      subject.max_hours_before_termination = described_class::MAX_HOURS_BEFORE_TERMINATION_LIMIT
      # noinspection RubyResolve
      expect(subject).to be_valid

      # noinspection RubyResolve
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
        build(:workspace, user: user, agent: agent_with_no_remote_development_config, project: project)
      end

      it 'validates presence of agent.remote_development_agent_config' do
        # sanity check of fixture
        expect(agent_with_no_remote_development_config.remote_development_agent_config).not_to be_present

        expect(subject).not_to be_valid
        expect(subject.errors[:agent]).to include('for Workspace must have an associated RemoteDevelopmentAgentConfig')
      end
    end

    context 'on project' do
      context 'when the project is not public' do
        let_it_be(:private_project) do
          create(:project, visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        subject do
          build(:workspace, user: user, project: private_project)
        end

        it 'validates project is public' do
          # sanity check of fixture
          expect(private_project).to be_private

          expect(subject).not_to be_valid
          expect(subject.errors[:project]).to include('for Workspace is required to be public')
        end
      end
    end
  end
end
