# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Identity Verification', :clean_gitlab_redis_rate_limiting, :js,
feature_category: :system_access do
  include EmailHelpers
  include SessionsHelper

  let(:new_user) { build_stubbed(:user) }
  let(:user) { User.find_by_username(new_user.username) }

  before do
    stub_application_setting_enum('email_confirmation_setting', 'hard')
    stub_application_setting(require_admin_approval_after_user_signup: false)

    stub_feature_flags(identity_verification_phone_number: false)
    stub_feature_flags(identity_verification_credit_card: false)

    # Identity Verification page requires the user to have an
    # `arkose_risk_band` to determine what verification methods will be
    # required. Here, we stub the `arkose_risk_band` method to return a valid
    # risk band value instead of solving the actual ArkoseLabs challenge
    stub_feature_flags(arkose_labs_signup_challenge: false)
    allow_next_found_instance_of(User) do |user|
      allow(user).to receive(:arkose_risk_band).and_return(arkose_risk_band)
    end
  end

  describe 'signing up' do
    # Having a 'low' ArkoseLabs risk band will require the user to verify
    # their email
    let(:arkose_risk_band) { 'low' }

    before do
      sign_up
    end

    it 'shows the verification page' do
      expect(page).to have_content(format(s_("IdentityVerification|For added security, you'll need to verify your "\
        "identity. We've sent a verification code to %{email}"), email: obfuscated_email(new_user.email)))
    end

    describe 'verifying the code' do
      it 'successfully confirms the user and shows the verification successful page' do
        verify_code confirmation_code

        expect(page).to have_current_path(success_identity_verification_path)
        expect(page).to have_content(s_('IdentityVerification|Verification successful'))
        expect(page).to have_selector(
          "meta[http-equiv='refresh'][content='3; url=#{users_sign_up_welcome_path}']", visible: :hidden
        )
      end

      it 'shows client side empty eror message' do
        verify_code ''

        expect(page).to have_content(s_('IdentityVerification|Enter a code.'))
      end

      it 'shows client side invalid eror message' do
        verify_code 'xxx'

        expect(page).to have_content(s_('IdentityVerification|Enter a valid code.'))
      end

      it 'shows a server side general error message' do
        user.confirm
        verify_code random_code(confirmation_code)

        expect(page).to have_content(s_('IdentityVerification|Something went wrong. Please try again.'))
      end

      it 'shows a server side rate limited error message' do
        code = confirmation_code
        (Gitlab::ApplicationRateLimiter.rate_limits[:email_verification][:threshold] + 1).times do
          verify_code random_code(code)
        end

        expect(page).to have_content(format(s_("IdentityVerification|You've reached the maximum amount of tries. "\
          'Wait %{interval} or send a new code and try again.'), interval: '10 minutes'))
      end

      it 'shows a server side invalid error message' do
        verify_code random_code(confirmation_code)

        expect(page).to have_content(s_('IdentityVerification|The code is incorrect. '\
          'Enter it again, or send a new code.'))
      end

      it 'shows a server side expired error message' do
        travel (Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES + 1).minutes
        verify_code confirmation_code

        expect(page).to have_content(s_('IdentityVerification|The code has expired. Send a new code and try again.'))
      end
    end

    describe 'resending the code' do
      it 'rate limits resending', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/375306' do
        (Gitlab::ApplicationRateLimiter.rate_limits[:email_verification_code_send][:threshold] + 1).times do
          click_link s_('IdentityVerification|Send a new code')
        end

        expect(page).to have_content(format(s_("IdentityVerification|You've reached the maximum amount of resends. "\
          'Wait %{interval} and try again.'), interval: 'about 1 hour'))
      end

      it 'shows an error when failing to resend' do
        user.confirm

        click_link s_('IdentityVerification|Send a new code')

        expect(page).to have_content(s_('IdentityVerification|Something went wrong. Please try again.'))
      end

      it 'resends a different code' do
        code = confirmation_code

        perform_enqueued_jobs do
          click_link s_('IdentityVerification|Send a new code')
          expect(page).to have_content(s_('IdentityVerification|A new code has been sent.'))
        end

        new_code = confirmation_code
        expect(code).not_to eq(new_code)
      end
    end
  end

  describe 'user that already went through identity verification' do
    let(:arkose_risk_band) { 'high' }

    it 'does not require identity verification again' do
      sign_up

      verify_code confirmation_code

      expect(page).to have_current_path(success_identity_verification_path)

      stub_feature_flags(identity_verification_credit_card: user)

      sign_out(user)

      gitlab_sign_in(user, password: new_user.password)

      expect(page).not_to have_current_path(identity_verification_path)
    end
  end

  def sign_up
    visit new_user_registration_path

    fill_in 'new_user_username', with: new_user.username
    fill_in 'new_user_email', with: new_user.email
    fill_in 'new_user_first_name', with: new_user.first_name
    fill_in 'new_user_last_name', with: new_user.last_name
    fill_in 'new_user_password', with: new_user.password

    perform_enqueued_jobs do
      click_button _('Register')
    end
  end

  def confirmation_code
    mail = find_email_for(new_user)
    expect(mail.to).to match_array([new_user.email])
    expect(mail.subject).to eq(s_('IdentityVerification|Confirm your email address'))
    code = mail.body.parts.first.to_s[/\d{#{Users::EmailVerification::GenerateTokenService::TOKEN_LENGTH}}/o]
    reset_delivered_emails!
    code
  end

  def verify_code(code)
    fill_in 'verification_code', with: code
    click_button s_('IdentityVerification|Verify email address')
  end

  def random_code(code)
    (different_code = rand.to_s[2..7]) == code ? random_code(code) : different_code
  end
end
