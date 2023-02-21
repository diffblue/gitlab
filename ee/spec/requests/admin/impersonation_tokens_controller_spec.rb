# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ImpersonationTokensController, :enable_admin_mode,
feature_category: :system_access do
  let(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  before do
    sign_in(admin)
  end

  context 'when impersonation is enabled' do
    before do
      stub_config_setting(impersonation_enabled: true)
    end

    context 'when personal access tokens are disabled' do
      before do
        stub_ee_application_setting(personal_access_tokens_disabled?: true)
      end

      it 'responds with a 404' do
        get admin_user_impersonation_tokens_path(user_id: user.username)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
