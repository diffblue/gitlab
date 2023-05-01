# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OrchestrationConfigurationCreateBotWorker, feature_category: :security_policy_management do
  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:security_orchestration_policy_configuration) do
      create(:security_orchestration_policy_configuration, project: project)
    end

    let_it_be(:current_user) { create(:user) }
    let(:security_orchestration_policy_configuration_id) { nil }

    subject(:run_worker) { described_class.new.perform(security_orchestration_policy_configuration_id, current_user) }

    before do
      project.add_owner(current_user)
    end

    it 'does not raise an error' do
      expect { run_worker }.not_to raise_error
    end

    context 'with valid security_orchestration_policy_configuration_id' do
      let(:security_orchestration_policy_configuration_id) { security_orchestration_policy_configuration.id }

      it 'creates and assignes a bot user', :aggregate_failures do
        expect { run_worker }.to change { User.count }.by(1)
        expect(security_orchestration_policy_configuration.reload.bot_user_id).not_to be_nil
      end

      it 'creates the bot with correct params', :aggregate_failures do
        run_worker

        bot_user = security_orchestration_policy_configuration.reload.bot_user

        expect(bot_user.name).to eq('GitLab Security Policy Bot')
        expect(bot_user.username).to start_with("gitlab_security_policy_project_#{project.id}_bot")
        expect(bot_user.email).to start_with("gitlab_security_policy_project_#{project.id}_bot")
        expect(bot_user.user_type).to eq('security_policy_bot')
      end

      it 'adds the bot user as a guest to the project', :aggregate_failures do
        expect { run_worker }.to change { project.members.count }.by(1)

        bot_user = security_orchestration_policy_configuration.reload.bot_user

        expect(project.members.find_by(user: bot_user).access_level).to eq(Gitlab::Access::GUEST)
      end

      context 'when a bot user is already assigned' do
        let_it_be(:bot_user) { create(:user, user_type: :security_policy_bot) }
        let_it_be(:security_orchestration_policy_configuration) do
          create(:security_orchestration_policy_configuration, bot_user: bot_user)
        end

        it 'does not assigne a new bot user', :aggregate_failures do
          run_worker

          expect(security_orchestration_policy_configuration.reload.bot_user_id).to equal(bot_user.id)
        end
      end
    end
  end
end
