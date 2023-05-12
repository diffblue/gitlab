# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Orchestration::CreateBotService, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project) }
  let!(:security_orchestration_policy_configuration) do
    create(:security_orchestration_policy_configuration, project: project)
  end

  let_it_be(:current_user) { create(:user) }

  subject(:execute_service) { described_class.new(security_orchestration_policy_configuration, current_user).execute }

  it 'raises an error', :aggregate_failures do
    expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
  end

  context 'when current_user can manage members' do
    before do
      project.add_owner(current_user)
    end

    it 'creates and assignes a bot user', :aggregate_failures do
      expect { execute_service }.to change { User.count }.by(1)
      expect(security_orchestration_policy_configuration.reload.bot_user_id).not_to be_nil
    end

    it 'creates the bot with correct params', :aggregate_failures do
      execute_service

      bot_user = security_orchestration_policy_configuration.reload.bot_user

      expect(bot_user.name).to eq('GitLab Security Policy Bot')
      expect(bot_user.username).to start_with("gitlab_security_policy_project_#{project.id}_bot")
      expect(bot_user.email).to start_with("gitlab_security_policy_project_#{project.id}_bot")
      expect(bot_user.user_type).to eq('security_policy_bot')
    end

    it 'adds the bot user as a guest to the project', :aggregate_failures do
      expect { execute_service }.to change { project.members.count }.by(1)

      bot_user = security_orchestration_policy_configuration.reload.bot_user

      expect(project.members.find_by(user: bot_user).access_level).to eq(Gitlab::Access::GUEST)
    end

    context 'when a bot user is already assigned' do
      let_it_be(:bot_user) { create(:user, user_type: :security_policy_bot) }
      let_it_be(:security_orchestration_policy_configuration) do
        create(:security_orchestration_policy_configuration, bot_user: bot_user)
      end

      it 'does not assigne a new bot user', :aggregate_failures do
        execute_service

        expect(security_orchestration_policy_configuration.reload.bot_user_id).to equal(bot_user.id)
      end
    end

    context 'when a part of the creation fails' do
      before do
        allow(security_orchestration_policy_configuration).to receive(:update!).and_raise(StandardError)
      end

      it 'reverts the previous actions' do
        previous_members = project.members

        expect { execute_service }.to raise_error(StandardError)

        expect(project.reload.members).to eq(previous_members)
      end
    end
  end

  context 'when security_orchestration_policy_configuration does not have a project' do
    let!(:security_orchestration_policy_configuration) do
      create(:security_orchestration_policy_configuration, :namespace)
    end

    it 'raises an error', :aggregate_failures do
      expect do
        execute_service
      end.to raise_error(described_class::SecurityOrchestrationPolicyConfigurationHasNoProjectError)
    end
  end
end
