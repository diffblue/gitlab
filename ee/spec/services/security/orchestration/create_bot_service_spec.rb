# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Orchestration::CreateBotService, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let!(:security_orchestration_policy_configuration) do
    create(:security_orchestration_policy_configuration, project: project)
  end

  let(:skip_authorization) { false }
  let(:current_user) { user }

  subject(:execute_service) do
    described_class.new(project, current_user, skip_authorization: skip_authorization).execute
  end

  context 'when current_user is missing' do
    let(:current_user) { nil }

    it 'raises an error', :aggregate_failures do
      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end

    context 'when skipping authorization' do
      let(:skip_authorization) { true }

      it 'creates and assigns a bot user', :aggregate_failures do
        expect { execute_service }.to change { User.count }.by(1)
        expect(project.security_policy_bot).to be_present
      end
    end
  end

  context 'when current_user cannot manage members' do
    it 'raises an error', :aggregate_failures do
      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end

    context 'when skipping authorization' do
      let(:skip_authorization) { true }

      it 'creates and assigns a bot user', :aggregate_failures do
        expect { execute_service }.to change { User.count }.by(1)
        expect(project.reload.security_policy_bot).to be_present
      end
    end
  end

  context 'when current_user can manage members' do
    before do
      project.add_owner(current_user)
    end

    it 'creates and assigns a bot user', :aggregate_failures do
      expect { execute_service }.to change { User.count }.by(1)
      expect(project.security_policy_bot).to be_present
    end

    it 'creates the bot with correct params', :aggregate_failures do
      execute_service

      bot_user = project.security_policy_bot

      expect(bot_user.name).to eq('GitLab Security Policy Bot')
      expect(bot_user.username).to start_with("gitlab_security_policy_project_#{project.id}_bot")
      expect(bot_user.email).to start_with("gitlab_security_policy_project_#{project.id}_bot")
      expect(bot_user.user_type).to eq('security_policy_bot')
    end

    it 'adds the bot user as a guest to the project', :aggregate_failures do
      expect { execute_service }.to change { project.members.count }.by(1)

      bot_user = project.security_policy_bot

      expect(project.members.find_by(user: bot_user).access_level).to eq(Gitlab::Access::GUEST)
    end

    context 'when a bot user is already assigned' do
      let_it_be(:bot_user) { create(:user, :security_policy_bot) }

      before do
        project.add_guest(bot_user)
      end

      it 'does not assign a new bot user', :aggregate_failures do
        expect { execute_service }.not_to change { User.count }

        expect(project.security_policy_bot.id).to equal(bot_user.id)
      end
    end

    context 'when a part of the creation fails' do
      before do
        allow(project).to receive(:add_guest).and_raise(StandardError)
      end

      it 'reverts the previous actions' do
        expect { execute_service }.to raise_error(StandardError).and(change { User.count }.by(0))
      end
    end
  end
end
