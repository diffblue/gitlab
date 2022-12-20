# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniauthCallbacksController, type: :controller, feature_category: :authentication_and_authorization do
  include LoginHelpers

  let_it_be(:extern_uid) { 'my-uid' }
  let_it_be(:provider) { :ldap }
  let_it_be(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }

  before do
    mock_auth_hash(provider.to_s, extern_uid, user.email)
    stub_omniauth_provider(provider, context: request)
  end

  context 'when sign in fails' do
    before do
      subject.response = ActionDispatch::Response.new

      allow(subject).to receive(:params)
        .and_return(ActionController::Parameters.new(username: user.username))

      stub_omniauth_failure(
        OmniAuth::Strategies::LDAP.new(nil),
        'invalid_credentials',
        OmniAuth::Strategies::LDAP::InvalidCredentialsError.new('Invalid credentials for ldap')
      )
    end

    it 'audits provider failed login when licensed' do
      stub_licensed_features(extended_audit_events: true)
      expect { subject.failure }.to change { AuditEvent.count }.by(1)
    end

    it 'does not audit provider failed login when unlicensed' do
      stub_licensed_features(extended_audit_events: false)
      expect { subject.failure }.not_to change { AuditEvent.count }
    end
  end

  describe 'identity verification', feature_category: :insider_threat do
    subject(:oauth_request) { post :saml }

    let_it_be(:provider) { 'google_oauth2' }

    before do
      mock_auth_hash(provider, extern_uid, user_email)
      stub_omniauth_saml_config(external_providers: [provider], block_auto_created_users: false)
      stub_omniauth_provider(provider, context: request)

      allow(::Users::EmailVerification::SendCustomConfirmationInstructionsService)
        .to receive(:identity_verification_enabled?).and_return(true)
    end

    shared_examples 'identity verification required' do
      it 'redirects to identity verification' do
        expect_any_instance_of(::Users::EmailVerification::SendCustomConfirmationInstructionsService) do |instance|
          expect(instance).to receive(:execute)
        end

        oauth_request

        expect(request.session[:verification_user_id]).not_to be_nil
        expect(response).to redirect_to(identity_verification_path)
      end
    end

    shared_examples 'identity verification not required' do
      it 'does not redirect to identity verification' do
        allow_any_instance_of(::Users::EmailVerification::SendCustomConfirmationInstructionsService) do |instance|
          expect(instance).not_to receive(:execute)
        end

        oauth_request

        expect(request.session[:verification_user_id]).to be_nil
        expect(response).not_to redirect_to(identity_verification_path)
      end
    end

    context 'on sign up' do
      let_it_be(:user_email) { 'test@example.com' }

      it_behaves_like 'identity verification required'

      context 'when auto blocking users after creation' do
        before do
          stub_omniauth_setting(block_auto_created_users: true)
        end

        it_behaves_like 'identity verification not required'
      end
    end

    context 'on sign in' do
      let_it_be(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }
      let_it_be(:user_email) { user.email }

      it_behaves_like 'identity verification not required'

      context 'when identity is not yet verified' do
        before do
          user.update!(confirmed_at: nil)
        end

        it_behaves_like 'identity verification required'
      end
    end
  end
end
