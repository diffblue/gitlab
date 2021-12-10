# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SCIM Token handling', :js do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    group.add_owner(user)
    stub_licensed_features(group_saml: true)
  end

  context 'when `scim_token_vue` feature flag is disabled' do
    before do
      stub_feature_flags(scim_token_vue: false)
    end

    describe 'group has no existing scim token' do
      before do
        sign_in(user)
        visit group_saml_providers_path(group)
      end

      it 'displays generate token form' do
        expect(page).to have_selector('.js-generate-scim-token-container', visible: true)
        expect(page).to have_selector('.js-scim-token-container', visible: false)

        page.within '.js-generate-scim-token-container' do
          expect(page).to have_content('Generate a SCIM token to set up your System for Cross-Domain Identity Management.')
          expect(page).to have_button('Generate a SCIM token')
        end
      end
    end

    describe 'group has existing scim token' do
      let!(:scim_token) { create(:scim_oauth_access_token, group: group) }

      before do
        sign_in(user)
        visit group_saml_providers_path(group)
      end

      it 'displays the scim form with an obfuscated token' do
        expect(page).to have_selector('.js-generate-scim-token-container', visible: false)
        expect(page).to have_selector('.js-scim-token-container', visible: true)

        page.within '.js-scim-token-container' do
          expect(page).to have_button('reset it.')
          expect(page.find('#scim_token').value).to eq('********************')
          expect(page.find('#scim_endpoint_url').value).to eq(scim_token.as_entity_json[:scim_api_url])
        end
      end
    end
  end

  def find_token_field
    page.find_field('Your SCIM token')
  end

  def find_api_endpoint_url_field
    page.find_field('SCIM API endpoint URL')
  end

  context 'when group has no existing SCIM token' do
    before do
      sign_in(user)
      visit group_saml_providers_path(group)
    end

    it 'displays generate token form' do
      expect(page).to have_content('Generate a SCIM token to set up your System for Cross-Domain Identity Management.')
      expect(page).to have_button('Generate a SCIM token')
    end
  end

  context 'when group has existing SCIM token' do
    let_it_be(:scim_token) { create(:scim_oauth_access_token, group: group) }

    before do
      sign_in(user)
      visit group_saml_providers_path(group)
    end

    it 'displays the SCIM form with an obfuscated token' do
      expect(page).to have_button('reset it')
      expect(find_token_field.value).to eq('********************')
      expect(page).not_to have_button('Click to reveal')
      expect(page).not_to have_button('Copy SCIM token')
      expect(find_api_endpoint_url_field.value).to eq(scim_token.as_entity_json[:scim_api_url])
    end

    context 'when `reset it` button is clicked' do
      before do
        accept_gl_confirm(
          'Are you sure you want to reset the SCIM token? SCIM provisioning will stop working until the new token is updated.',
          button_text: 'Reset SCIM token'
        ) do
          page.click_button('reset it')
        end
      end

      it 'displays the SCIM form with an obfuscated token that can be copied or shown' do
        expect(find_api_endpoint_url_field.value).to eq(scim_token.as_entity_json[:scim_api_url])

        expect(page).to have_button('Copy SCIM token')

        expect(find_token_field.value).to eq('********************')
        page.click_button('Click to reveal')
        expect(find_token_field.value).not_to eq('********************')
        expect(find_token_field.value).not_to eq('')
      end
    end
  end
end
