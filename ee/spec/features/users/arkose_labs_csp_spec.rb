# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ArkoseLabs content security policy' do
  shared_examples 'configures Content Security Policy headers correctly' do
    context 'when feature flag is enabled' do
      let(:feature_flag_state) { true }

      it 'adds ArkoseLabs URL to Content Security Policy headers' do
        visit page_path

        expect(response_headers['Content-Security-Policy']).to include('https://*.arkoselabs.com')
      end
    end

    context 'when feature flag is disabled' do
      let(:feature_flag_state) { false }

      it 'does not add ArkoseLabs URL to Content Security Policy headers' do
        visit page_path

        expect(response_headers['Content-Security-Policy']).not_to include('https://*.arkoselabs.com')
      end
    end
  end

  context 'when in login page' do
    let(:page_path) { root_path }

    before do
      stub_feature_flags(
        arkose_labs_signup_challenge: false,
        arkose_labs_login_challenge: feature_flag_state
      )
    end

    it_behaves_like 'configures Content Security Policy headers correctly'
  end

  context 'when in registration page' do
    let(:page_path) { new_user_registration_path }

    before do
      stub_feature_flags(
        arkose_labs_login_challenge: false,
        arkose_labs_signup_challenge: feature_flag_state
      )
    end

    it_behaves_like 'configures Content Security Policy headers correctly'
  end
end
