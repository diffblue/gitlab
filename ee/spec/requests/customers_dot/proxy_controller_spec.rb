# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomersDot::ProxyController, type: :request, feature_category: :customersdot_application do
  describe 'POST graphql' do
    let_it_be(:customers_dot) { ::Gitlab::Routing.url_helpers.subscription_portal_graphql_url }
    let_it_be(:default_headers) { { 'Content-Type' => 'application/json' } }

    shared_examples 'customersdot proxy' do
      it 'forwards request body to customers dot' do
        request_params = '{ "foo" => "bar" }'

        stub_request(:post, customers_dot)

        post customers_dot_proxy_graphql_path, params: request_params

        expect(WebMock).to have_requested(:post, customers_dot).with(body: request_params, headers: headers)
      end

      it 'responds with customers dot status' do
        stub_request(:post, customers_dot).to_return(status: 500)

        post customers_dot_proxy_graphql_path

        expect(response).to have_gitlab_http_status(:internal_server_error)
      end

      it 'responds with customers dot response body' do
        customers_dot_response = 'foo'

        stub_request(:post, customers_dot).to_return(body: customers_dot_response)

        post customers_dot_proxy_graphql_path

        expect(response.body).to eq(customers_dot_response)
      end
    end

    context 'with user signed in' do
      let(:headers) { default_headers.merge(auth_header) }
      let(:auth_header) { { 'Authorization' => "Bearer #{jwt}" } }
      let(:jwt) { Gitlab::CustomersDot::Jwt.new(user).encoded }
      let(:user) { create(:user) }
      let(:rsa_key) { OpenSSL::PKey::RSA.generate(1024) }
      let(:jwt_jti) { 'jwt_jti' }

      before do
        stub_application_setting(customers_dot_jwt_signing_key: rsa_key.to_s )
        allow(SecureRandom).to receive(:uuid).and_return(jwt_jti)

        sign_in(user)

        freeze_time
      end

      it_behaves_like 'customersdot proxy'
    end

    context 'with no user signed in' do
      let(:headers) { default_headers }

      it_behaves_like 'customersdot proxy'
    end
  end
end
