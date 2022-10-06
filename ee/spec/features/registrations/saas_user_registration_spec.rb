# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User registration", :js, :saas do
  include AfterNextHelpers
  include LoginHelpers
  include DeviseHelpers
  include TermsHelper

  before do
    stub_feature_flags(
      # This is a feature flag to update the single-sign on registration flow
      # to match the standard registration flow
      update_oauth_registration_flow: true,

      arkose_labs_signup_challenge: false
    )

    stub_application_setting(
      # Saas doesn't require admin approval.
      require_admin_approval_after_user_signup: false
    )

    stub_omniauth_setting(
      # users can sign up on saas freely.
      block_auto_created_users: false
    )
  end

  describe "single-sign on registration flow" do
    before do
      stub_omniauth_provider(provider)
      register_via(provider, uid, email)
      clear_browser_session

      # terms are enforced by default in saas
      enforce_terms
    end

    around do |example|
      with_omniauth_full_host { example.run }
    end

    context "when provider sends verified email address" do
      let(:provider) { 'github' }
      let(:uid) { 'my-uid' }
      let(:email) { 'user@github.com' }

      it "presents the initial welcome step" do
        expect(page).to have_current_path users_sign_up_welcome_path
        expect(page).to have_content('Welcome to GitLab, mockuser!')
      end
    end

    context "when provider does not send a verified email address" do
      let(:provider) { 'github' }
      let(:uid) { 'my-uid' }
      let(:email) { 'temp-email-for-oauth@email.com' }

      it "presents the profile page to add an email address" do
        expect(page).to have_current_path profile_path
        expect(page).to have_content('Please complete your profile with email address')
      end
    end
  end
end
