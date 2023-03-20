# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Identity Verification', :js, :saas, feature_category: :instance_resiliency do
  include SubscriptionPortalHelpers
  include IdentityVerificationHelpers

  before do
    stub_feature_flags(soft_email_confirmation: false)
    stub_application_setting_enum('email_confirmation_setting', 'hard')
    stub_application_setting(
      require_admin_approval_after_user_signup: false,
      arkose_labs_public_api_key: 'public_key',
      arkose_labs_private_api_key: 'private_key',
      telesign_customer_xid: 'customer_id',
      telesign_api_key: 'private_key'
    )
  end

  let(:user_email) { 'onboardinguser@example.com' }
  let(:user) { User.find_by_email(user_email) }

  shared_examples 'registering the user with low risk identity verification' do
    let(:risk) { :low }

    it 'verifies the user' do
      expect_to_see_identity_verification_page

      verify_email

      expect_to_see_verification_successful_page

      expect_to_see_welcome_page
    end
  end

  shared_examples 'registering the user with medium risk identity verification' do
    let(:risk) { :medium }

    it 'verifies the user' do
      expect_to_see_identity_verification_page

      verify_phone_number

      verify_email

      expect_to_see_verification_successful_page

      expect_to_see_welcome_page
    end
  end

  shared_examples 'registering the user with high risk identity verification' do
    let(:risk) { :high }

    it 'verifies the user' do
      expect_to_see_identity_verification_page

      verify_credit_card

      verify_phone_number

      verify_email

      expect_to_see_verification_successful_page

      expect_to_see_welcome_page
    end
  end

  describe 'Standard flow' do
    before do
      visit new_user_registration_path
      sign_up
    end

    it_behaves_like 'registering the user with low risk identity verification'
    it_behaves_like 'registering the user with medium risk identity verification'
    it_behaves_like 'registering the user with high risk identity verification'
  end

  describe 'Invite flow' do
    let(:invitation) { create(:group_member, :invited, :developer, invite_email: user_email) }
    let(:risk) { :high }

    # The invite flow does present the Arkose challenge, so pass a risk score, but do not verify identity.
    # See issue here: https://gitlab.com/gitlab-org/modelops/anti-abuse/team-tasks/-/issues/127
    it 'registers the user' do
      visit invite_path(invitation.raw_invite_token, invite_type: Emails::Members::INITIAL_INVITE)

      sign_up

      expect_to_see_welcome_page
    end
  end

  describe 'Trial flow' do
    before do
      visit new_trial_registration_path
      trial_sign_up
    end

    it_behaves_like 'registering the user with low risk identity verification'
    it_behaves_like 'registering the user with medium risk identity verification'
    it_behaves_like 'registering the user with high risk identity verification'
  end

  describe 'SAML flow' do
    let(:provider) { 'google_oauth2' }

    before do
      mock_auth_hash(provider, 'external_uid', user_email)
      stub_omniauth_setting(block_auto_created_users: false)

      visit new_user_registration_path
      saml_sign_up
    end

    around do |example|
      with_omniauth_full_host { example.run }
    end

    it_behaves_like 'registering the user with low risk identity verification'
    it_behaves_like 'registering the user with medium risk identity verification'
    it_behaves_like 'registering the user with high risk identity verification'
  end

  describe 'Subscription flow' do
    before do
      stub_signing_key
      stub_invoice_preview

      visit new_subscriptions_path
      sign_up
    end

    it_behaves_like 'registering the user with low risk identity verification'
    it_behaves_like 'registering the user with medium risk identity verification'
    it_behaves_like 'registering the user with high risk identity verification'
  end

  private

  def sign_up
    fill_in_user_sign_up_form
    solve_arkose_verify_challenge
    click_button _('Register')
  end

  def saml_sign_up
    click_link "oauth-login-#{provider}"
    solve_arkose_verify_challenge(saml: true)
  end

  def trial_sign_up
    fill_in_user_sign_up_form
    solve_arkose_verify_challenge
    click_button _('Continue')
  end

  def fill_in_user_sign_up_form
    new_user = build(:user, email: user_email)

    fill_in _('First name'), with: new_user.first_name
    fill_in _('Last name'), with: new_user.last_name
    fill_in _('Username'), with: new_user.username
    fill_in _('Email'), with: new_user.email
    fill_in _('Password'), with: new_user.password

    wait_for_all_requests
  end

  def expect_to_see_identity_verification_page
    expect(page).to have_content("For added security, you'll need to verify your identity")
  end

  def verify_credit_card
    # It's too hard to simulate an actual credit card validation, since it relies on loading an external script,
    # rendering external content in an iframe and several API calls to the subscription portal from the backend.
    # So instead we create a credit_card_validation directly and reload the page here.
    create(:credit_card_validation, user: user)
    visit current_path
  end

  def verify_phone_number
    phone_number = '311234567890'
    verification_code = '4319315'
    stub_telesign_verification(phone_number, verification_code)

    page.find('[data-testid="country-form-select"]').find("option[value$='+#{phone_number.first(2)}']").select_option
    fill_in 'phone_number', with: phone_number.from(2)
    click_button s_('IdentityVerification|Send code')

    expect(page).to have_content(format(s_("IdentityVerification|We've sent a verification code to +%{phoneNumber}"),
      phoneNumber: phone_number))

    fill_in 'verification_code', with: verification_code
    click_button s_('IdentityVerification|Verify phone number')
  end

  def verify_email
    expect(page).to have_content(format(s_("IdentityVerification|We've sent a verification code to %{email}"),
      email: Gitlab::Utils::Email.obfuscated_email(user_email)))

    fill_in 'verification_code', with: email_verification_code
    click_button s_('IdentityVerification|Verify email address')
  end

  def expect_to_see_verification_successful_page
    expect(page).to have_content(s_('IdentityVerification|Verification successful'))

    click_link 'refresh the page'
  end

  def expect_to_see_welcome_page
    expect(page).to have_content(_(format('Welcome to GitLab, %{first_name}!', first_name: user.first_name)))
  end
end
