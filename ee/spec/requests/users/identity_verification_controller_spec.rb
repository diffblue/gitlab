# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::IdentityVerificationController, type: :request do
  describe 'GET #show' do
    let_it_be(:current_user) { create(:user) }

    before do
      sign_in(current_user) if current_user.present?
    end

    subject(:request) { get users_identity_verification_path }

    it 'renders show template' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:show)
    end

    context 'when identity_verification feature-flag is disabled' do
      before do
        stub_feature_flags(identity_verification: false)
      end

      it 'renders not found' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with unauthorized user' do
      let(:current_user) { nil }

      it 'renders redirects to sign_in path' do
        request

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
