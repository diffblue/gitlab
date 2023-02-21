# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OmniAuth Kerberos SPNEGO', feature_category: :system_access do
  let(:path) { '/users/auth/kerberos/negotiate' }
  let(:controller_class) { OmniauthKerberosController }

  before do
    # In production user_kerberos_omniauth_callback_path is defined
    # dynamically early when the app boots. Because this is hard to set up
    # during testing we stub out this path helper on the controller.
    omniauth_kerberos = OmniAuth::Strategies::Kerberos.new(:app)
    allow(omniauth_kerberos).to receive(:script_name).and_return('')
    allow_any_instance_of(OmniAuth::Strategies::Kerberos).to receive(:new).and_return(omniauth_kerberos)
    allow_any_instance_of(controller_class).to receive(:user_kerberos_omniauth_callback_path)
      .and_return(omniauth_kerberos.callback_path)
  end

  it 'asks for an SPNEGO token' do
    get path

    expect(response).to have_gitlab_http_status(:unauthorized)
    expect(response.header['Www-Authenticate']).to eq('Negotiate')
  end

  context 'when an SPNEGO token is provided' do
    it 'passes the token to spnego_negotiate!' do
      expect_any_instance_of(controller_class).to receive(:spnego_credentials!)
        .with('fake spnego token')

      get path, params: {}, headers: spnego_header
    end
  end

  context 'when the final SPNEGO token is provided' do
    before do
      expect_any_instance_of(controller_class).to receive(:spnego_credentials!)
        .with('fake spnego token').and_return('janedoe@EXAMPLE.COM')
    end

    it 'redirects to the omniauth callback' do
      get path, params: {}, headers: spnego_header

      expect(response).to redirect_to('/users/auth/kerberos/callback')
    end

    it 'stores the users principal name in the session' do
      get path, params: {}, headers: spnego_header

      expect(session[:kerberos_principal_name]).to eq('janedoe@EXAMPLE.COM')
    end

    it 'send the final SPNEGO response' do
      allow_any_instance_of(controller_class).to receive(:spnego_response_token)
        .and_return("it's the final token")

      get path, params: {}, headers: spnego_header

      expect(response.header['Www-Authenticate']).to eq(
        "Negotiate #{Base64.strict_encode64("it's the final token")}"
      )
    end
  end

  def spnego_header
    { 'HTTP_AUTHORIZATION' => "Negotiate #{Base64.strict_encode64('fake spnego token')}" }
  end
end
