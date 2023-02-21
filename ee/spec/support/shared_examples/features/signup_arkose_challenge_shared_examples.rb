# frozen_string_literal: true

RSpec.shared_examples 'creates a user with ArkoseLabs risk band' do
  let(:mock_arkose_labs_token) { 'mock_arkose_labs_session_token' }
  let(:mock_arkose_labs_key) { 'private_key' }
  let(:arkose_verification_response) do
    Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response.json')))
  end

  before do
    stub_feature_flags(arkose_labs_signup_challenge: true)
    stub_application_setting(
      arkose_labs_public_api_key: 'public_key',
      arkose_labs_private_api_key: mock_arkose_labs_key
    )

    request_headers = {
      Accept: '*/*',
      'Accept-Encoding': 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'User-Agent': 'Ruby'
    }
    response_headers = { 'Content-Type' => 'application/json' }
    stub_request(:post, "https://verify-api.arkoselabs.com/api/v4/verify/")
      .with(
        body: "private_key=#{mock_arkose_labs_key}&session_token=#{mock_arkose_labs_token}",
        headers: request_headers
      ).to_return(status: 200, body: arkose_verification_response.to_json, headers: response_headers)

    visit signup_path

    # Since we don't want to execute actual HTTP requests in tests we can't have
    # the frontend show the ArkoseLabs challenge. Instead, we imitate what
    # happens when ArkoseLabs does not show (suppressed: true) the challenge -
    # i.e. the ArkoseLabs session token is assigned as the value of a hidden
    # input field in the signup form.
    selector = '[data-testid="arkose-labs-token-input"]'
    page.execute_script("document.querySelector('#{selector}').value = '#{mock_arkose_labs_token}'")
    page.execute_script("document.querySelector('#{selector}').dispatchEvent(new Event('input'))")
  end

  it 'creates the user', :js do
    fill_and_submit_signup_form

    created_user = User.find_by_email!(user_email)

    expect(created_user).not_to be_nil
    expect(UserCustomAttribute.find_by(user: created_user, key: 'arkose_risk_band')).not_to be_nil
  end
end
