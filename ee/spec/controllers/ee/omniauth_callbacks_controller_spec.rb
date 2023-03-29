# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniauthCallbacksController, type: :controller, feature_category: :system_access do
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

  describe '#openid_connect' do
    let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }
    let(:extern_uid) { 'my-uid' }
    let(:provider) { 'openid_connect' }

    before do
      prepare_provider_route('openid_connect')

      allow(Gitlab::Auth::OAuth::Provider).to(
        receive_messages({ providers: [:openid_connect],
                           config_for: openid_connect_config })
      )
      stub_omniauth_setting(
        { enabled: true,
          allow_single_sign_on: ['openid_connect'],
          providers: [openid_connect_config] }
      )

      request.env['devise.mapping'] = Devise.mappings[:user]
      request.env['omniauth.auth'] = Rails.application.env_config['omniauth.auth']
    end

    context 'when auth hash is missing required groups' do
      let(:openid_connect_config) do
        {
          'name' => 'openid_connect',
          'args' => {
            'name' => 'openid_connect',
            'client_options' => {
              'identifier' => 'gitlab-test-client',
              'gitlab' => {
                'required_groups' => ['Owls']
              }
            }
          }
        }
      end

      before do
        mock_auth_hash(provider.to_s, extern_uid, user.email, additional_info: {})
      end

      context 'when licensed feature is available' do
        before do
          stub_licensed_features(oidc_client_groups_claim: true)
        end

        it 'prevents sign in' do
          post provider

          expect(request.env['warden']).not_to be_authenticated
        end
      end

      context 'when licensed feature is not available' do
        it 'allows sign in' do
          post provider

          expect(request.env['warden']).to be_authenticated
        end
      end
    end
  end

  describe 'identity verification', feature_category: :insider_threat do
    subject(:oauth_request) { post :saml }

    let_it_be(:provider) { 'google_oauth2' }

    before do
      mock_auth_hash(provider, extern_uid, user_email)
      stub_omniauth_saml_config(external_providers: [provider], block_auto_created_users: false)
      stub_omniauth_provider(provider, context: request)
    end

    shared_examples 'identity verification required' do
      it 'handles sticking, sets the session and redirects to identity verification', :aggregate_failures do
        expect_any_instance_of(::Users::EmailVerification::SendCustomConfirmationInstructionsService) do |instance|
          expect(instance).to receive(:execute)
        end

        expect(User.sticking)
          .to receive(:stick_or_unstick_request)
          .with(anything, :user, anything)

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

        expect(User.sticking).not_to receive(:stick_or_unstick_request)

        oauth_request

        expect(request.session[:verification_user_id]).to be_nil
        expect(response).not_to redirect_to(identity_verification_path)
      end
    end

    context 'on sign up' do
      before do
        allow_next_instance_of(User) do |user|
          allow(user).to receive(:identity_verification_enabled?).and_return(true)
        end
      end

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
      before do
        allow_next_found_instance_of(User) do |user|
          allow(user).to receive(:identity_verification_enabled?).and_return(true)
        end
      end

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
