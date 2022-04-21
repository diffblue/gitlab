# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ArkoseLabs content security policy' do
  let(:user) { create(:user) }

  before do
    stub_feature_flags(arkose_labs_login_challenge: true)
  end

  it 'has proper Content Security Policy headers' do
    visit root_path

    expect(response_headers['Content-Security-Policy']).to include('https://client-api.arkoselabs.com')
  end
end
