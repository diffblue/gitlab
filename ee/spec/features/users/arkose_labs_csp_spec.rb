# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ArkoseLabs content security policy' do
  let(:user) { create(:user) }

  it 'has proper Content Security Policy headers' do
    visit root_path

    expect(response_headers['Content-Security-Policy']).to include('https://client-api.arkoselabs.com')
  end
end
