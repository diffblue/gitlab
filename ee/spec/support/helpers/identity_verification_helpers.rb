# frozen_string_literal: true

module IdentityVerificationHelpers
  def solve_arkose_verify_challenge(saml: false, risk: :low)
    stub_request(:post, 'https://verify-api.arkoselabs.com/api/v4/verify/').to_return(
      status: 200,
      body: { session_risk: { risk_band: risk.capitalize } }.to_json,
      headers: { content_type: 'application/json' }
    )

    selector = '[data-testid="arkose-labs-token-input"]'
    page.execute_script("document.querySelector('#{selector}').value='mock_arkose_labs_session_token'")
    if saml
      page.execute_script("document.querySelector('[data-testid=\"arkose-labs-token-form\"]').submit()")
    else
      page.execute_script("document.querySelector('#{selector}').dispatchEvent(new Event('input'))")
    end
  end

  def stub_telesign_verification(phone_number, verification_code)
    reference_id = 'xxx'

    stub_request(:get, "https://rest-ww.telesign.com/v1/phoneid/score/#{phone_number}?request_risk_insights=true&ucid=BACF")
      .to_return(status: 200, body: { phone_type: { description: 'MOBILE' }, risk: { score: 97 } }.to_json)

    stub_request(:post, 'https://rest-ww.telesign.com/v1/verify/sms')
      .to_return(status: 200, body: { reference_id: reference_id }.to_json)

    stub_request(:get, "https://rest-ww.telesign.com/v1/verify/#{reference_id}?verify_code=#{verification_code}")
      .to_return(status: 200, body: { verify: { code_state: 'VALID' } }.to_json)
  end

  def email_verification_code
    perform_enqueued_jobs

    mail = ActionMailer::Base.deliveries.find { |d| d.to.include?(user_email) }
    expect(mail.subject).to eq(s_('IdentityVerification|Confirm your email address'))

    mail.body.parts.first.to_s[/\d{#{Users::EmailVerification::GenerateTokenService::TOKEN_LENGTH}}/o]
  end

  def verify_email
    content = format(
      s_("IdentityVerification|We've sent a verification code to %{email}"),
      email: Gitlab::Utils::Email.obfuscated_email(user_email)
    )
    expect(page).to have_content(content)

    fill_in 'verification_code', with: email_verification_code
    click_button s_('IdentityVerification|Verify email address')
  end

  def expect_to_see_identity_verification_page
    expect(page).to have_content("For added security, you'll need to verify your identity")
  end

  def expect_to_see_verification_successful_page
    expect(page).to have_content(s_('IdentityVerification|Verification successful'))

    click_link 'refresh the page'
  end
end
