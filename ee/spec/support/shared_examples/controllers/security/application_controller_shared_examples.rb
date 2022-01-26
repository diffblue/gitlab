# frozen_string_literal: true

RSpec.shared_examples Security::ApplicationController do
  context 'when the user is authenticated' do
    let(:security_application_controller_user) { create(:user) }

    before do
      stub_licensed_features(security_dashboard: true)
      sign_in(security_application_controller_user)
    end

    it 'responds with success' do
      security_application_controller_child_action

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'and the instance does not have an Ultimate license' do
      it '404s' do
        stub_licensed_features(security_dashboard: false)

        security_application_controller_child_action

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'when the user is not authenticated' do
    it 'redirects the user to the sign in page' do
      security_application_controller_child_action

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
