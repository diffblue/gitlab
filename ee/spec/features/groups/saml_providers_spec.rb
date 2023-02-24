# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SAML provider settings', feature_category: :system_access do
  let_it_be_with_refind(:user) { create(:user) }
  let_it_be_with_refind(:group) { create(:group) }

  let(:callback_path) { "/groups/#{group.path}/-/saml/callback" }

  before_all do
    group.add_owner(user)
  end

  before do
    stub_default_url_options(protocol: "https")
    stub_saml_config
  end

  # This emulate a successful response from the SAML provider
  around do |example|
    with_omniauth_full_host { example.run }
  end

  def submit
    click_button('Save changes')
  end

  def test_sso
    click_link('Verify SAML Configuration')
  end

  def stub_saml_config
    stub_licensed_features(group_saml: true)
    allow(Devise).to receive(:omniauth_providers).and_return(%i[group_saml])
  end

  describe 'settings' do
    before do
      sign_in(user)
    end

    it 'displays required information to user' do
      visit group_saml_providers_path(group)

      within '.saml-settings' do
        expect(find_field('Assertion consumer service URL').value).to eq group.build_saml_provider.assertion_consumer_service_url
        expect(find_field('Identifier').value).to eq "https://localhost/groups/#{group.full_path}"
      end
    end

    it 'provides metadata XML' do
      visit group_saml_providers_path(group)

      StrategyHelpers.without_test_mode do
        click_link('metadata')
      end

      expect(page.body).to include(callback_path)
      expect(response_headers['Content-Type']).to have_content("application/xml")
    end

    context '"Enforce SSO-only authentication for web activity for this group" checkbox' do
      it 'is checked by default' do
        visit group_saml_providers_path(group)

        expect(find_field('Enforce SSO-only authentication for web activity for this group')).to be_checked
      end

      it 'displays warning if unchecked', :js do
        visit group_saml_providers_path(group)

        uncheck 'Enforce SSO-only authentication for web activity for this group'

        expect(page).to have_content 'Warning - Enable SSO enforcement to reduce security risks.'
      end
    end

    it 'allows creation of new provider' do
      visit group_saml_providers_path(group)

      fill_in 'Identity provider single sign-on URL', with: 'https://localhost:9999/adfs/ls'
      fill_in 'Certificate fingerprint', with: 'aa:bb:cc:dd:ee:ff:11:22:33:44:55:66:77:88:99:0a:1b:2c:3d:00'

      expect { submit }.to change { SamlProvider.count }.by(1)
    end

    it 'shows errors if fields missing' do
      visit group_saml_providers_path(group)

      submit

      expect(find('.gl-alert-danger')).to have_text("Certificate fingerprint can't be blank")
    end

    context 'with existing SAML provider' do
      let!(:saml_provider) { create(:saml_provider, group: group, prohibited_outer_forks: false, enforced_sso: true) }

      it 'allows provider to be disabled', :js do
        visit group_saml_providers_path(group)

        uncheck 'Enable SAML authentication for this group'

        expect { submit }.to change { saml_provider.reload.enabled }.to false
      end

      it 'displays user login URL' do
        visit group_saml_providers_path(group)

        login_url = find('label', text: 'GitLab single sign-on URL').find('~* a').text

        expect(login_url).to include "/groups/#{group.full_path}/-/saml/sso"
        expect(login_url).to end_with "?token=#{group.reload.saml_discovery_token}"
      end

      it 'updates the enforced sso setting', :js do
        visit group_saml_providers_path(group)

        uncheck 'Enforce SSO-only authentication for web activity for this group'

        expect { submit }.to change { saml_provider.reload.enforced_sso }.to(false)
        expect(page).to have_content 'Warning - Enable SSO enforcement to reduce security risks.'
      end

      context 'enforced_group_managed_accounts enabled', :js do
        before do
          create(:group_saml_identity, saml_provider: saml_provider, user: user)
          stub_feature_flags(group_managed_accounts: true)
        end

        it 'updates the enforced_group_managed_accounts flag' do
          visit group_saml_providers_path(group)

          check 'Enforce users to have dedicated group-managed accounts for this group'

          expect { submit }.to change { saml_provider.reload.enforced_group_managed_accounts }.to(true)
        end

        it 'updates the prohibited_outer_forks flag' do
          visit group_saml_providers_path(group)

          check 'Enforce users to have dedicated group-managed accounts for this group'
          check 'Prohibit outer forks for this group'

          expect { submit }.to change { saml_provider.reload.prohibited_outer_forks }.to(true)
        end
      end

      context 'enforced_group_managed_accounts disabled' do
        it 'does not render toggles' do
          stub_feature_flags(group_managed_accounts: false)

          visit group_saml_providers_path(group)

          expect(page).not_to have_field('Enforce users to have dedicated group-managed accounts for this group')
          expect(page).not_to have_field('Prohibit outer forks for this group')
        end
      end
    end

    describe 'test button' do
      let!(:saml_provider) { create(:saml_provider, group: group) }
      let(:raw_saml_response) do
        fixture = File.read('ee/spec/fixtures/saml/response.xml')
        Base64.encode64(fixture)
      end

      before do
        mock_group_saml(uid: '123')
        allow_next_instance_of(Gitlab::Auth::GroupSaml::ResponseStore) do |instance|
          allow(instance).to receive(:get_raw).and_return(raw_saml_response)
        end

        stub_const(
          '::OmniAuth::Strategies::GroupSaml::VERIFY_SAML_RESPONSE',
          group_saml_providers_path(group)
        )
      end

      it 'displays XML validation errors', :aggregate_failures do
        visit group_saml_providers_path(group)

        test_sso

        expect(page).to have_current_path(group_saml_providers_path(group))
        expect(page).to have_content("Fingerprint mismatch")
        expect(page).to have_content("The attributes have expired, based on the SessionNotOnOrAfter")
      end

      it 'displays SAML Response XML' do
        visit group_saml_providers_path(group)

        test_sso

        expect(page).to have_content("<saml:Issuer>")
      end
    end
  end

  describe '#sso' do
    context 'with no SAML provider configured' do
      it 'acts as if the group was not found' do
        visit sso_group_saml_providers_path(group)

        expect(page).to have_current_path(new_user_session_path)
      end

      context 'as owner' do
        before do
          sign_in(user)
        end

        it 'redirects to settings page with warning' do
          visit sso_group_saml_providers_path(group)

          expect(page).to have_current_path(group_saml_providers_path(group))
          expect(page).to have_content 'SAML sign on has not been configured for this group'
        end
      end
    end

    context 'with existing SAML provider' do
      let!(:saml_provider) { create(:saml_provider, group: group) }

      context 'when not signed in', :js do
        it "shows the sso page so user can sign in" do
          visit sso_group_saml_providers_path(group)

          expect(page).to have_content('SAML single sign-on')
          expect(page).to have_content("Sign in to #{group.full_name}")
        end
      end

      context 'when signed in' do
        before do
          sign_in(user)
        end

        it 'shows warning that linking accounts authorizes control over sign in' do
          visit sso_group_saml_providers_path(group)

          expect(page).to have_content(/Allow .* to sign you in/)
          expect(page).to have_content('Authorize')
        end

        it 'Authorize/link button redirects to auth flow' do
          external_uid = '98765'
          mock_group_saml(uid: external_uid)
          visit sso_group_saml_providers_path(group)

          click_link 'Authorize'

          expect(page).to have_content("Your organization's SSO has been connected to your GitLab account")
          expect(user.identities.last.extern_uid).to eq external_uid
        end

        context 'with linked account' do
          before do
            identity = create(:group_saml_identity, saml_provider: saml_provider, user: user)
            mock_group_saml(uid: identity.extern_uid)
          end

          it 'sign in button redirects to auth flow' do
            visit sso_group_saml_providers_path(group)

            click_link 'Sign in with single sign-on'

            expect(page).to have_current_path group_path(group), ignore_query: true
            expect(page).to have_content('Already signed in')
          end
        end
      end

      context 'when user has access locked', :js do
        before do
          user.lock_access!
          identity = create(:group_saml_identity, saml_provider: saml_provider, user: user)
          mock_group_saml(uid: identity.extern_uid)
        end

        it 'warns user that their account is locked' do
          visit sso_group_saml_providers_path(group)

          click_link 'Sign in'

          expect(page).to have_content('Your account is locked.')
        end

        context 'with 2FA' do
          before do
            user.update!(otp_required_for_login: true)
          end

          it 'warns user their account is locked' do
            visit sso_group_saml_providers_path(group)

            click_link 'Sign in'

            expect(page).to have_content('Your account is locked.')
            expect(page).to have_current_path sso_group_saml_providers_path(group), ignore_query: true
          end
        end
      end

      context 'for a private group' do
        let(:group) { create(:group, :private) }

        context 'when not signed in' do
          it "doesn't show sso page" do
            visit sso_group_saml_providers_path(group)

            expect(page).to have_current_path(new_user_session_path, ignore_query: true)
          end

          it "shows the sso page if the token is given" do
            visit sso_group_saml_providers_path(group, token: group.saml_discovery_token)

            expect(page).to have_current_path sso_group_saml_providers_path(group), ignore_query: true
          end
        end

        context 'when signed in' do
          before do
            sign_in(user)

            visit sso_group_saml_providers_path(group)
          end

          it 'displays sign in button' do
            expect(page).to have_current_path sso_group_saml_providers_path(group), ignore_query: true

            within '.login-box' do
              expect(page).to have_link 'Authorize'
            end
          end

          it "doesn't leak group information" do
            expect(page).not_to have_selector('.group-avatar')
            expect(page).not_to have_selector('.nav-sidebar')
          end
        end
      end
    end
  end
end
