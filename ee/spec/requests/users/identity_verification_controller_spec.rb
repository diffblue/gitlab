# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::IdentityVerificationController, type: :request do
  describe 'GET #show' do
    let(:current_user) { create(:user) }

    before do
      sign_in(current_user) if current_user.present?
    end

    subject(:show_identity_verification) { get users_identity_verification_path }

    context 'when identity_verification feature-flag is enabled' do
      before do
        stub_feature_flags(identity_verification: true)
      end

      it 'renders template' do
        show_identity_verification

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end

    context 'when identity_verification feature-flag is disabled' do
      before do
        stub_feature_flags(identity_verification: false)
      end

      it 'renders not found' do
        show_identity_verification

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with unauthorized user' do
      let(:current_user) { nil }

      it 'renders redirects to sign_in path' do
        show_identity_verification

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
