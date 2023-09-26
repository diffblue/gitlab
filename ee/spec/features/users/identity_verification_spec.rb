# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Identity Verification', :clean_gitlab_redis_rate_limiting, :js,
  feature_category: :system_access do
  include EmailHelpers
  include SessionsHelper
  include IdentityVerificationHelpers

  let(:new_user) { build_stubbed(:user, :no_super_sidebar) }
  let(:user) { User.find_by_username(new_user.username) }

  before do
    stub_application_setting_enum('email_confirmation_setting', 'hard')
    stub_application_setting(require_admin_approval_after_user_signup: false)

    stub_feature_flags(identity_verification_phone_number: false)
    stub_feature_flags(identity_verification_credit_card: false)
    stub_feature_flags(moved_mr_sidebar: false)

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
      expect(page).to have_content(s_(
        "IdentityVerification|For added security, you'll need to verify your identity in a few quick steps."
      ))

      expect(page).to have_content(
        format(s_("IdentityVerification|We've sent a verification code to %{email}"),
          email: obfuscated_email(new_user.email))
      )
    end

    describe 'verifying the code' do
      shared_examples 'successfully confirms the user' do
        it 'successfully confirms the user and shows the completed badge and next button' do
          verify_code confirmation_code

          expect_verification_completed
        end
      end

      it_behaves_like 'successfully confirms the user'

      it 'shows client side empty eror message' do
        verify_code ''

        expect(page).to have_content(s_('IdentityVerification|Enter a code.'))
      end

      it 'shows client side invalid error message' do
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

      context 'when user email is mixed case' do
        let(:new_user) { build_stubbed(:user, email: 'testEmailAddress@example.com') }

        it_behaves_like 'successfully confirms the user'
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

      expect_verification_completed

      stub_feature_flags(identity_verification_credit_card: true)

      user_signs_out

      gitlab_sign_in(user, password: new_user.password)

      expect(page).not_to have_current_path(identity_verification_path)
    end
  end

  def sign_up
    visit new_user_registration_path

    perform_enqueued_jobs do
      fill_in_sign_up_form(new_user)
    end
  end

  def random_code(code)
    (different_code = rand.to_s[2..7]) == code ? random_code(code) : different_code
  end

  def user_signs_out
    find_by_testid('user-dropdown').click
    click_link 'Sign out'

    expect(page).to have_button('Sign in')
  end
end
