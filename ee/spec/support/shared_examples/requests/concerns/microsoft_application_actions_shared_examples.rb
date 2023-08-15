# frozen_string_literal: true

RSpec.shared_examples_for 'Microsoft application controller actions' do
  let(:params) do
    { system_access_microsoft_application: attributes_for(:system_access_microsoft_application) }
  end

  context 'when Microsoft Group Sync is not enabled' do
    before do
      allow(::Gitlab::Auth::Saml::Config).to receive(:microsoft_group_sync_enabled?).and_return(false)
    end

    it 'renders 404 not found' do
      put path, params: params

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when Microsoft Group Sync is enabled' do
    before do
      allow(::Gitlab::Auth::Saml::Config).to receive(:microsoft_group_sync_enabled?).and_return(true)
    end

    it 'raises an error when parameters are missing' do
      expect { put path }.to raise_error(ActionController::ParameterMissing)
    end

    it 'redirects with error alert when missing required attributes' do
      put path, params: { system_access_microsoft_application: { enabled: true } }

      expect(response).to have_gitlab_http_status(:redirect)
      expect(flash[:alert]).to include('Microsoft Azure integration settings failed to save.')
    end

    it 'redirects with success notice' do
      put path, params: params

      expect(response).to have_gitlab_http_status(:redirect)
      expect(flash[:notice]).to eq(s_('Microsoft|Microsoft Azure integration settings were successfully updated.'))
    end
  end
end
