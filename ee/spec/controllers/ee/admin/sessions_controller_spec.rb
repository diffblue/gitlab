# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::SessionsController, :do_not_mock_admin_mode,
  feature_category: :system_access do
  include_context 'custom session'

  describe '#create' do
    context 'when using two-factor authentication' do
      def authenticate_2fa(otp_user_id: user.id, **user_params)
        post(:create, params: { user: user_params }, session: { otp_user_id: otp_user_id })
      end

      before do
        sign_in(user)
        controller.current_user_mode.request_admin_mode!
      end

      context 'when OTP authentication fails' do
        it_behaves_like 'an auditable failed authentication' do
          let(:user) { create(:admin, :two_factor) }
          let(:operation) { authenticate_2fa(otp_attempt: 'invalid', otp_user_id: user.id) }
          let(:method) { 'OTP' }
        end
      end

      context 'when WebAuthn authentication fails' do
        before do
          stub_feature_flags(webauthn: true)
          webauthn_authenticate_service = instance_spy(Webauthn::AuthenticateService, execute: false)
          allow(Webauthn::AuthenticateService).to receive(:new).and_return(webauthn_authenticate_service)
        end

        it_behaves_like 'an auditable failed authentication' do
          let(:user) { create(:admin, :two_factor_via_webauthn) }
          let(:operation) { authenticate_2fa(device_response: 'invalid', otp_user_id: user.id) }
          let(:method) { 'WebAuthn' }
        end
      end
    end
  end
end
