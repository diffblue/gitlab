# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group SAML SSO', :js, :snowplow, feature_category: :system_access do
  include CookieHelper

  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let!(:saml_provider) { create(:saml_provider, group: group, enforced_sso: true, enforced_group_managed_accounts: true) }

  let(:saml_response) do
    fixture = File.read('ee/spec/fixtures/saml/response.xml')
    OneLogin::RubySaml::Response.new(Base64.encode64(fixture))
  end

  let(:saml_oauth_info) do
    Hash[*saml_response.attributes.to_h.flatten(2)]
  end

  around do |example|
    with_omniauth_full_host { example.run }
  end

  before do
    stub_feature_flags(group_managed_accounts: true, sign_up_on_sso: true, convert_user_to_group_managed_accounts: true)
    stub_licensed_features(group_saml: true)
    allow(Devise).to receive(:omniauth_providers).and_return(%i(group_saml))

    Warden.on_next_request do |proxy|
      proxy.raw_session['oauth_data'] = OmniAuth::AuthHash.new(info: saml_oauth_info, response_object: saml_response, uid: saml_response.name_id)
      proxy.raw_session['oauth_group_id'] = group.id
    end
  end

  context 'sign_up' do
    context 'when signed in' do
      before do
        sign_in(user)
        mock_group_saml(uid: '1')

        visit group_sign_up_path(group)
      end

      context 'SAML response includes a verified email from the logged in user' do
        let(:user) { create(:user, email: saml_oauth_info['email']) }

        it 'allows to complete the transfer and sign in to the group' do
          expect(page).to have_link('Authorize')

          click_link 'Authorize'

          expect(page).to have_button('Transfer ownership')

          click_button('Transfer ownership')

          expect(page).to have_content('This action can lead to data loss. To prevent accidental actions we ask you to confirm your intention.')
          expect(page).to have_content("Please type #{user.username} to proceed or close this modal to cancel.")

          fill_in 'confirm_name_input', with: user.username
          click_button 'Confirm'

          expect(page).to have_current_path(group_path(group))
        end
      end

      it "doesn't display the authorize tab" do
        expect(page).not_to have_link('Authorize')
      end
    end
  end

  context 'convert_user_to_group_managed_accounts flag is disable' do
    before do
      stub_feature_flags(convert_user_to_group_managed_accounts: false)
      sign_in(user)
      mock_group_saml(uid: '1')

      visit group_sign_up_path(group)
    end

    it "doesn't display the authorize tab" do
      expect(page).not_to have_link('Authorize')
    end
  end
end
