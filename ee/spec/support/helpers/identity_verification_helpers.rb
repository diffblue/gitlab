# frozen_string_literal: true

module IdentityVerificationHelpers
  def solve_arkose_verify_challenge(saml: false)
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

  def stub_telesign_verification
    allow_next_instance_of(::PhoneVerification::TelesignClient::RiskScoreService) do |service|
      allow(service).to receive(:execute).and_return(
        ServiceResponse.success(payload: { risk_score: 80 })
      )
    end

    allow_next_instance_of(::PhoneVerification::TelesignClient::SendVerificationCodeService) do |service|
      allow(service).to receive(:execute).and_return(
        ServiceResponse.success(payload: { telesign_reference_xid: '123' })
      )
    end

    allow_next_instance_of(::PhoneVerification::TelesignClient::VerifyCodeService) do |service|
      allow(service).to receive(:execute).and_return(
        ServiceResponse.success(payload: { telesign_reference_xid: '123' })
      )
    end
  end

  def email_verification_code
    perform_enqueued_jobs

    mail = ActionMailer::Base.deliveries.find { |d| d.to.include?(user_email) }
    expect(mail.subject).to eq(s_('IdentityVerification|Confirm your email address'))

    mail.body.parts.first.to_s[/\d{#{Users::EmailVerification::GenerateTokenService::TOKEN_LENGTH}}/o]
  end
end
