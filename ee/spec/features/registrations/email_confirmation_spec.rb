# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Email Confirmation', feature_category: :onboarding do
  include EmailHelpers
  include SessionsHelper

  let_it_be(:new_user) { build_stubbed(:user) }
  let_it_be(:admin) { create(:user, :admin) }

  let(:user) { User.find_by_username(new_user.username) }

  where(identity_verification: [true, false],
        require_admin_approval_after_user_signup: [true, false],
        email_confirmation_setting: %w[off soft hard])

  with_them do
    before do
      stub_feature_flags(arkose_labs_signup_challenge: false)
      stub_feature_flags(identity_verification_credit_card: false)

      stub_feature_flags(identity_verification: identity_verification)
      stub_application_setting(require_admin_approval_after_user_signup: require_admin_approval_after_user_signup)
      stub_application_setting_enum('email_confirmation_setting', email_confirmation_setting)

      sign_up
    end

    it 'confirms identity and signs in successfully', :aggregate_failures, :js, :enable_admin_mode do
      expect_required_approval_and_sign_in if require_admin_approval_after_user_signup

      unless Gitlab::CurrentSettings.email_confirmation_setting_off?
        if Gitlab::CurrentSettings.email_confirmation_setting_soft?
          expect_successful_sign_in_and_confirmation_banner
          expect_successful_resend_instructions(from_banner: true)
          expect_successful_devise_confirmation
        elsif require_admin_approval_after_user_signup
          expect_unsuccessful_sign_in
          expect_successful_resend_instructions
          expect_successful_devise_confirmation
          sign_in
        elsif identity_verification
          expect_successful_resend_instructions(custom: true)
          expect_successful_custom_confirmation
        else
          expect_almost_there_page
          expect_unsuccessful_sign_in
          expect_successful_resend_instructions
          expect_successful_devise_confirmation
          sign_in
        end
      end

      expect_to_be_confirmed_and_signed_in
    end
  end

  context 'when signing up through SAML' do
    let(:external_uid) { 'my-uid' }
    let(:user) { create(:omniauth_user, :unconfirmed, extern_uid: external_uid, provider: 'saml') }

    before do
      stub_application_setting_enum('email_confirmation_setting', 'soft')
      stub_feature_flags(identity_verification: true)
      stub_omniauth_saml_config(enabled: true, auto_link_saml_user: true)
      gitlab_sign_in_via('saml', user, external_uid)
    end

    it 'signs in successfully' do
      expect(page).to have_current_path(root_path)
      expect_successful_resend_instructions(from_banner: true)
      expect_successful_devise_confirmation
      expect(user.reload.confirmed?).to be(true)
    end
  end

  def sign_up
    visit new_user_registration_path

    fill_in 'new_user_username', with: new_user.username
    fill_in 'new_user_email', with: new_user.email
    fill_in 'new_user_first_name', with: new_user.first_name
    fill_in 'new_user_last_name', with: new_user.last_name
    fill_in 'new_user_password', with: new_user.password

    wait_for_all_requests

    perform_enqueued_jobs { click_button _('Register') }
  end

  def sign_in
    fill_in 'user_login', with: user.username
    fill_in 'user_password', with: new_user.password

    wait_for_all_requests

    click_button _('Sign in')
  end

  def expect_to_be_signed_out_with_message(notice)
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content(notice)
  end

  def expect_successful_sign_in_and_confirmation_banner
    expect(page).to have_current_path(users_sign_up_welcome_path)
    expect(page).to have_content('Please check your email')
  end

  def expect_unsuccessful_sign_in
    sign_in

    expect_to_be_signed_out_with_message _('Please confirm your email address')
  end

  def expect_required_approval_and_sign_in
    expect_to_be_signed_out_with_message 'You have signed up successfully. However, we could not sign you in because '\
      'your account is awaiting approval from your GitLab administrator.'

    should_not_email(user)

    sign_in

    expect_to_be_signed_out_with_message 'Your account is pending approval from your GitLab administrator and hence '\
      'blocked. Please contact your GitLab administrator if you think this is an error.'

    perform_enqueued_jobs { Users::ApproveService.new(admin).execute(user) }

    number_of_emails = email_confirmation_setting == 'off' ? 1 : 2

    should_email(user, times: number_of_emails) # welcome email and optional confirmation email

    sign_in
  end

  def expect_almost_there_page
    expect(page).to have_current_path(users_almost_there_path(email: user.email))

    visit new_user_session_path
  end

  def expect_successful_resend_instructions(from_banner: false, custom: false)
    reset_delivered_emails!

    if from_banner
      perform_enqueued_jobs { click_link _('Resend it') }
    elsif custom
      perform_enqueued_jobs do
        click_link s_('IdentityVerification|Send a new code')
        expect(page).to have_content(s_('IdentityVerification|A new code has been sent.'))
      end
    else
      visit new_user_confirmation_path

      fill_in 'user_email', with: user.email

      perform_enqueued_jobs { click_button _('Resend') }

      expect(page).to have_current_path(users_almost_there_path)
    end

    should_email(user)
  end

  def expect_successful_devise_confirmation
    mail = find_email_for(user)
    reset_delivered_emails!

    expect(mail.subject).to eq('Confirmation instructions')

    visit user_confirmation_path(confirmation_token: user.confirmation_token)

    expect(page).to have_content('Your email address has been successfully confirmed.')
  end

  def expect_successful_custom_confirmation
    expect(page).to have_current_path(identity_verification_path)
    expect(page).to have_content(format(s_("IdentityVerification|For added security, you'll need to verify your "\
      "identity. We've sent a verification code to %{email}"), email: obfuscated_email(user.email)))

    mail = find_email_for(user)
    reset_delivered_emails!

    expect(mail.subject).to eq(s_('IdentityVerification|Confirm your email address'))

    code = mail.body.parts.first.to_s[/\d{#{Users::EmailVerification::GenerateTokenService::TOKEN_LENGTH}}/o]
    fill_in 'verification_code', with: code
    click_button s_('IdentityVerification|Verify email address')

    expect(page).to have_content(s_('IdentityVerification|Verification successful'))
  end

  def expect_to_be_confirmed_and_signed_in
    expect(user.reload.confirmed?).to be(true)
    expect(page).to have_current_path(users_sign_up_welcome_path)
  end
end
