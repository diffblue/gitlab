# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Login', feature_category: :system_access do
  include LdapHelpers
  include UserLoginHelper
  include DeviseHelpers

  before do
    stub_licensed_features(extended_audit_events: true)
  end

  it 'creates a security event for an invalid password login' do
    user = create(:user)

    expect { gitlab_sign_in(user, password: 'incorrect-password') }
      .to change { AuditEvent.where(entity_id: -1).count }.from(0).to(1)
  end

  it 'creates a security event for an invalid OAuth login' do
    stub_omniauth_saml_config(
      enabled: true,
      auto_link_saml_user: false,
      allow_single_sign_on: ['saml'],
      providers: [mock_saml_config]
    )

    user = create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: 'saml')

    expect { gitlab_sign_in_via('saml', user, 'wrong-uid') }
      .to change { AuditEvent.where(entity_id: -1).count }.from(0).to(1)
  end

  it 'creates a security event for an invalid one-time code' do
    user = create(:user, :two_factor)
    gitlab_sign_in(user)

    expect do
      fill_in 'user_otp_attempt', with: 'invalid_code'
      click_button 'Verify code'
    end.to change { AuditEvent.count }.by(1)
  end

  describe 'smartcard authentication' do
    before do
      allow(Gitlab.config.smartcard).to receive(:enabled).and_return(true)
    end

    subject { visit new_user_session_path }

    context 'when smartcard is enabled' do
      context 'with smartcard_auth feature flag off' do
        before do
          stub_licensed_features(smartcard_auth: false)
        end

        it 'does not render any tabs' do
          subject

          ensure_no_tabs
        end

        it 'renders link to sign up path' do
          visit new_user_session_path

          expect(page.body).to have_link('Register now', href: new_user_registration_path)
        end
      end

      context 'with smartcard_auth feature flag on' do
        before do
          stub_licensed_features(smartcard_auth: true)
        end

        it 'correctly renders tabs and panes' do
          subject

          ensure_tab_pane_correctness(%w(Smartcard Standard))
        end

        it 'renders link to sign up path' do
          visit new_user_session_path

          expect(page.body).to have_link('Register now', href: new_user_registration_path)
        end

        describe 'with two-factor authentication required', :clean_gitlab_redis_sessions do
          let_it_be(:user) { create(:user) }
          let_it_be(:smartcard_identity) { create(:smartcard_identity, user: user) }

          before do
            stub_application_setting(require_two_factor_authentication: true)
          end

          context 'with a smartcard session' do
            let(:openssl_certificate_store) { instance_double(OpenSSL::X509::Store) }
            let(:openssl_certificate) do
              instance_double(OpenSSL::X509::Certificate, subject: smartcard_identity.subject, issuer: smartcard_identity.issuer)
            end

            it 'does not ask for Two-Factor Authentication' do
              allow(Gitlab::Auth::Smartcard::Certificate).to receive(:store).and_return(openssl_certificate_store)
              allow(OpenSSL::X509::Certificate).to receive(:new).and_return(openssl_certificate)
              allow(openssl_certificate_store).to receive(:verify).and_return(true)

              # Loging using smartcard
              visit verify_certificate_smartcard_path(client_certificate: openssl_certificate)

              visit profile_path

              expect(page).not_to have_content(_('Enter verification code'))
            end
          end

          context 'without a smartcard session' do
            it 'asks for Two-Factor Authentication' do
              sign_in(user)

              visit profile_path

              expect(page).to have_content(_('Enter verification code'))
            end
          end
        end
      end
    end
  end

  describe 'smartcard authentication against LDAP server' do
    let(:ldap_server_config) do
      {
        'provider_name' => 'ldapmain',
        'attributes' => {},
        'encryption' => 'plain',
        'smartcard_auth' => smartcard_auth_status,
        'uid' => 'uid',
        'base' => 'dc=example,dc=com'
      }
    end

    subject { visit new_user_session_path }

    before do
      stub_licensed_features(smartcard_auth: true)
      stub_ldap_setting(enabled: true)
      allow(Gitlab.config.smartcard).to receive(:enabled).and_return(true)
      allow(::Gitlab::Auth::Ldap::Config).to receive_messages(enabled: true, servers: [ldap_server_config])
      allow_any_instance_of(ActionDispatch::Routing::RoutesProxy)
        .to receive(:user_ldapmain_omniauth_callback_path)
              .and_return('/users/auth/ldapmain/callback')
    end

    context 'when smartcard auth is optional' do
      let(:smartcard_auth_status) { 'optional' }

      it 'correctly renders tabs and panes' do
        subject

        ensure_one_active_tab
        ensure_one_active_pane
      end

      it 'shows LDAP login form' do
        subject

        expect(page).to have_selector('#ldapmain.tab-pane form#new_ldap_user')
      end

      it 'shows LDAP smartcard login form' do
        subject

        expect(page).to have_selector('#ldapmain_smartcard input[value="Sign in with smart card"]')
      end
    end

    context 'when smartcard auth is required' do
      let(:smartcard_auth_status) { 'required' }

      it 'correctly renders tabs and panes' do
        subject

        ensure_one_active_tab
        ensure_one_active_pane
      end

      it 'does not show LDAP login form' do
        subject

        expect(page).not_to have_selector('#ldapmain.tab-pane form#new_ldap_user')
      end

      it 'shows LDAP smartcard login form' do
        subject

        expect(page).to have_selector('#ldapmain_smartcard input[value="Sign in with smart card"]')
      end
    end
  end

  describe 'via Group SAML', :saas do
    let(:saml_provider) { create(:saml_provider) }
    let(:group) { saml_provider.group }
    let(:identity) { create(:group_saml_identity, user: user, saml_provider: saml_provider) }

    before do
      stub_licensed_features(group_saml: true)
      mock_group_saml(uid: identity.extern_uid)
    end

    around do |example|
      with_omniauth_full_host { example.run }
    end

    context 'with enforced terms' do
      include TermsHelper

      let(:user) { create(:user) }

      it 'shows the terms disclaimer' do
        enforce_terms

        visit sso_group_saml_providers_path(group)

        expect(page).to have_content('By clicking Sign in or registering through a third party you accept the GitLab Terms of Use and acknowledge the Privacy Policy and Cookie Policy')
      end
    end

    context 'with WebAuthn two factor', :js do
      let(:user) { create(:user, :two_factor_via_webauthn) }

      before do
        mock_group_saml(uid: identity.extern_uid)
      end

      it 'shows WebAuthn prompt after SAML' do
        visit sso_group_saml_providers_path(group, token: group.saml_discovery_token)

        click_link 'Sign in'

        # Mock the webauthn procedure to neither reject or resolve, just do nothing
        # Using the built-in credentials.get functionality would result in an SecurityError
        # as these tests are executed using an IP-address as effective domain
        page.execute_script <<~JS
          navigator.credentials.get = function() {
            return new Promise((resolve) => {
              window.gl.resolveWebauthn = resolve;
            });
          }
        JS

        click_button(_('Try again?'))

        expect(page).to have_content('Trying to communicate with your device')
        expect(page).to have_button(_('Sign in via 2FA code'))

        fake_successful_webauthn_authentication

        expect(page).to have_current_path group_path(group), ignore_query: true
      end
    end
  end

  describe 'restricted visibility levels' do
    context 'contains public level' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'hides Explore link' do
        visit new_user_session_path

        expect(page).to have_no_link("Explore")
      end

      it 'hides help link' do
        visit new_user_session_path

        expect(page).to have_no_link("Help")
      end
    end

    context 'does not contain public level' do
      it 'displays Explore and Help links' do
        visit new_user_session_path

        href = find_link("Help")[:href]

        expect(href).to eq("/help")
        expect(page).to have_link("Explore")
      end
    end
  end
end
