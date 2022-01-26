# frozen_string_literal: true

RSpec.shared_examples 'security dashboard JSON endpoint' do
  context 'when the user is authenticated' do
    let(:security_application_controller_user) { create(:user) }

    before do
      stub_licensed_features(security_dashboard: true)

      login_as(security_application_controller_user)
    end

    it 'responds with success' do
      security_dashboard_request

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'and the instance does not have an Ultimate license' do
      it '404s' do
        stub_licensed_features(security_dashboard: false)

        security_dashboard_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'when the user is not authenticated' do
    it 'responds with a 401' do
      security_dashboard_request

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end
end
