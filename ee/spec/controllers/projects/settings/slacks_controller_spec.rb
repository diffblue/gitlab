# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::SlacksController, feature_category: :integrations do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET show' do
    def redirect_url(project)
      edit_project_settings_integration_path(
        project,
        project.build_gitlab_slack_application_integration
      )
    end

    def stub_service(result)
      service = double
      expect(service).to receive(:execute).and_return(result)
      expect(Projects::SlackApplicationInstallService)
        .to receive(:new).with(project, user, anything).and_return(service)
    end

    context 'when valid CSRF token is provided' do
      before do
        expect(controller).to receive(:check_oauth_state).and_return(true)
      end

      it 'calls service and redirects with no alerts if result is successful' do
        stub_service(status: :success)

        get :slack_auth, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(redirect_url(project))
        expect(flash[:alert]).to be_nil
        expect(session[:slack_install_success]).to be(true)
      end

      it 'calls service and redirects with the alert if there is error' do
        stub_service(status: :error, message: 'error')

        get :slack_auth, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(redirect_url(project))
        expect(flash[:alert]).to eq('error')
      end
    end

    context 'when no CSRF token is provided' do
      it 'returns 403' do
        get :slack_auth, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
