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

    it 'audits provider failed login when licensed', :aggregate_failures do
      stub_licensed_features(extended_audit_events: true)

      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including({
        name: "omniauth_login_failed"
      })).and_call_original

      expect { subject.failure }.to change { AuditEvent.count }.by(1)

      expect(AuditEvent.last).to have_attributes(
        attributes: hash_including({
          "author_name" => user.username,
          "entity_type" => "User",
          "target_details" => user.username
        }),
        details: hash_including({
          failed_login: "LDAP",
          author_name: user.username,
          target_details: user.username,
          custom_message: "LDAP login failed"
        })
      )
    end

    it 'does not audit provider failed login when unlicensed' do
      stub_licensed_features(extended_audit_events: false)
      expect { subject.failure }.not_to change { AuditEvent.count }
    end
  end

  describe '#openid_connect' do
    let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }
    let(:provider) { :openid_connect }

    before do
      prepare_provider_route(provider)

      allow(Gitlab::Auth::OAuth::Provider).to(
        receive_messages({ providers: [provider],
                           config_for: connect_config })
      )
      stub_omniauth_setting(
        { enabled: true,
          allow_single_sign_on: [provider],
          providers: [connect_config] }
      )

      request.env['devise.mapping'] = Devise.mappings[:user]
      request.env['omniauth.auth'] = Rails.application.env_config['omniauth.auth']
    end

    context 'when auth hash is missing required groups' do
      let(:connect_config) do
        ActiveSupport::InheritableOptions.new({
          'name' => provider,
          'args' => {
            'name' => provider,
            'client_options' => {
              'identifier' => 'gitlab-test-client',
              'gitlab' => {
                'required_groups' => ['Owls']
              }
            }
          }
        })
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

    context 'when linking to existing profile' do
      let(:user) { create(:user) }
      let(:connect_config) do
        ActiveSupport::InheritableOptions.new({
          'name' => provider,
          'args' => {
            'name' => provider,
            'client_options' => {
              'identifier' => 'gitlab-test-client'
            }
          }
        })
      end

      before do
        sign_in user
        stub_licensed_features(oidc_client_groups_claim: true)
      end

      it 'links identity' do
        expect { post provider }.to change { user.identities.count }.by(1)
      end
    end
  end

  describe '#saml' do
    let(:mock_saml_response) { File.read('spec/fixtures/authentication/saml_response.xml') }
    let(:provider) { 'saml_okta' }

    controller(described_class) do
      alias_method :saml_okta, :handle_omniauth
    end

    context "with required_groups on saml config" do
      before do
        allow(routes).to receive(:generate_extras).and_return(['/users/auth/saml_okta/callback', []])

        saml_config = GitlabSettings::Options.new(name: 'saml_okta',
          required_groups: ['Freelancers'],
          groups_attribute: 'groups',
          label: 'saml_okta',
          args: {
            'strategy_class' => 'OmniAuth::Strategies::SAML'
          })
        stub_omniauth_saml_config(
          enabled: true,
          auto_link_saml_user: true,
          providers: [saml_config]
        )
      end

      it 'fails to authenticate' do
        post :saml_okta, params: { SAMLResponse: mock_saml_response }
        expect(request.env['warden']).not_to be_authenticated
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

  context 'with strategies', :aggregate_failures do
    let(:provider) { :github }
    let(:check_namespace_plan) { true }

    before do
      stub_ee_application_setting(should_check_namespace_plan: check_namespace_plan)
      stub_feature_flags(ensure_onboarding: true)
      stub_omniauth_setting(block_auto_created_users: false)
    end

    context 'when user is not registered yet' do
      let(:user) { build_stubbed(:user, email: 'new@example.com') }

      context 'when onboarding is enforced' do
        it 'redirects to welcome path with onboarding setup' do
          post provider

          expect(request.env['warden']).to be_authenticated
          expect_to_be_onboarding(response, user.email)
        end

        context 'when glm and trial params exist' do
          let(:omniauth_params) { { glm_source: '_glm_source_', glm_content: '_glm_content_', trial: true } }

          before do
            request.env['omniauth.params'] = omniauth_params.stringify_keys
          end

          it 'redirects to welcome path with onboarding setup with passed params' do
            post provider

            expect(request.env['warden']).to be_authenticated
            expect_to_be_onboarding(response, user.email, omniauth_params)
          end
        end
      end

      context 'when onboarding is not enforced' do
        let(:check_namespace_plan) { false }

        it 'redirects to welcome path without onboarding setup' do
          post provider

          expect(response).to redirect_to(users_sign_up_welcome_path)
          expect_to_not_be_onboarding(user.email)
        end
      end
    end

    context 'when user is already registered' do
      let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }

      it 'does not have onboarding setup and redirects to root path' do
        post provider

        expect(request.env['warden']).to be_authenticated
        expect(response).to redirect_to(root_path)
        expect_to_not_be_onboarding(user.email)
      end
    end

    def expect_to_not_be_onboarding(email)
      created_user = User.find_by_email(email)
      expect(created_user).not_to be_onboarding_in_progress
      expect(created_user.user_detail.onboarding_step_url).to be_nil
    end

    def expect_to_be_onboarding(response, email, params = {})
      expect(response).to redirect_to(users_sign_up_welcome_path(params))
      created_user = User.find_by_email(email)
      expect(created_user).to be_onboarding_in_progress
      expect(created_user.user_detail.onboarding_step_url).to eq(users_sign_up_welcome_path(params))
    end
  end
end
