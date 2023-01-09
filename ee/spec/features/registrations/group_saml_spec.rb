# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group-saml single-sign on registration flow', :js, :saas, feature_category: :onboarding do
  include TermsHelper
  include LoginHelpers

  let_it_be(:saml_provider) { create(:saml_provider) }
  let_it_be(:group) { saml_provider.group }
  let_it_be(:extern_uid) { '1234' }
  let_it_be(:email) { 'name@example.com' }

  before do
    stub_application_setting(require_admin_approval_after_user_signup: false)
    stub_omniauth_setting(block_auto_created_users: false)

    stub_licensed_features(group_saml: true)
    mock_group_saml(uid: extern_uid)
  end

  around do |example|
    with_omniauth_full_host { example.run }
  end

  shared_examples 'auto accepts terms and redirects to the group path' do
    it 'auto accepts terms and redirects to the group path' do
      visit sso_group_saml_providers_path(group, token: group.saml_discovery_token)

      click_link 'Sign in'

      expect(page).to have_current_path(group_path(group))
      expect(page).to have_content('Signed in with SAML')
    end
  end

  context 'when terms are enforced' do
    before do
      enforce_terms
    end

    context 'when user does not exist in gitlab' do
      it_behaves_like 'auto accepts terms and redirects to the group path'
    end

    context 'when user exists in gitlab with group-saml identity linked' do
      let!(:user) { create(:omniauth_user, extern_uid: extern_uid, saml_provider: saml_provider) }

      it_behaves_like 'auto accepts terms and redirects to the group path'
    end

    context 'when user exists in gitlab without group-saml identity linked' do
      let(:user) { create(:user, email: email) }

      before do
        sign_in(user)
      end

      it 'auto accepts terms and redirects to the group path' do
        visit sso_group_saml_providers_path(group, token: group.saml_discovery_token)

        expect_to_be_on_terms_page

        click_button 'Accept terms'
        wait_for_requests

        click_link 'Authorize'

        expect(page).to have_current_path(group_path(group))
        expect(page).to have_content("Your organization's SSO has been connected to your GitLab account")
      end
    end
  end

  context 'when terms are not enforced' do
    context 'when user does not exist in gitlab' do
      it_behaves_like 'auto accepts terms and redirects to the group path'
    end

    context 'when user exists in gitlab with group-saml identity linked' do
      let!(:user) { create(:omniauth_user, extern_uid: extern_uid, saml_provider: saml_provider) }

      it_behaves_like 'auto accepts terms and redirects to the group path'
    end

    context 'when user exists in gitlab without group-saml identity linked' do
      let(:user) { create(:user, email: email) }

      before do
        sign_in(user)
      end

      it 'auto accepts terms and redirects to the group path' do
        visit sso_group_saml_providers_path(group, token: group.saml_discovery_token)

        click_link 'Authorize'

        expect(page).to have_current_path(group_path(group))
        expect(page).to have_content("Your organization's SSO has been connected to your GitLab account")
      end
    end
  end
end
