# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::IntegrationsController, feature_category: :integrations do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  shared_examples 'endpoint with some disabled integrations' do
    it 'has some disabled integrations' do
      get :index, params: { namespace_id: project.namespace, project_id: project }

      expect(active_services).not_to include(*disabled_integrations)
    end
  end

  shared_examples 'endpoint without disabled integrations' do
    it 'does not have disabled integrations' do
      get :index, params: { namespace_id: project.namespace, project_id: project }

      expect(active_services).to include(*disabled_integrations)
    end
  end

  context 'sets correct services list' do
    let(:active_services) { assigns(:integrations).map(&:model_name) }
    let(:disabled_integrations) { %w[Integrations::Github] }

    it 'enables SlackSlashCommands and disables GitlabSlackApplication' do
      get :index, params: { namespace_id: project.namespace, project_id: project }

      expect(active_services).to include('Integrations::SlackSlashCommands')
      expect(active_services).not_to include('Integrations::GitlabSlackApplication')
    end

    it 'enables GitlabSlackApplication and disables SlackSlashCommands' do
      stub_application_setting(slack_app_enabled: true)
      allow(::Gitlab).to receive(:com?).and_return(true)

      get :index, params: { namespace_id: project.namespace, project_id: project }

      expect(active_services).to include('Integrations::GitlabSlackApplication')
      expect(active_services).not_to include('Integrations::SlackSlashCommands')
    end

    context 'without a license key' do
      it_behaves_like 'endpoint with some disabled integrations'
    end

    context 'with a license key' do
      let_it_be(:namespace) { create(:group, :private) }
      let_it_be(:project) { create(:project, :private, namespace: namespace) }

      before do
        create(:license, plan: ::License::PREMIUM_PLAN)
      end

      context 'when checking if namespace plan is enabled' do
        before do
          stub_application_setting(check_namespace_plan: true)
        end

        it_behaves_like 'endpoint with some disabled integrations'
      end

      context 'when checking if namespace plan is not enabled' do
        before do
          stub_application_setting(check_namespace_plan: false)
        end

        it_behaves_like 'endpoint without disabled integrations'
      end
    end
  end
end
