# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::Configuration, feature_category: :not_owned do # rubocop: disable  RSpec/InvalidFeatureCategory
  subject(:configuration) { described_class.new }

  describe '#access_token', :clean_gitlab_redis_cache do
    context 'when the token is cached', :use_clean_rails_redis_caching do
      let(:cached_token) { SecureRandom.uuid }

      before do
        Rails.cache.write(:tofa_access_token, cached_token)
      end

      it 'returns the cached token' do
        expect(configuration.access_token).to eq(cached_token)
      end
    end

    context 'when an access token has not been minted yet' do
      let(:access_token) { "x.#{SecureRandom.uuid}.z" }
      let(:private_key) { OpenSSL::PKey::RSA.new(4096) }
      let(:credentials) do
        {
          type: "service_account",
          project_id: SecureRandom.uuid,
          private_key_id: SecureRandom.hex(20),
          private_key: private_key.to_pem,
          client_email: "vertex-ai@#{SecureRandom.hex(4)}.iam.gserviceaccount.com",
          client_id: "1",
          auth_uri: "https://accounts.google.com/o/oauth2/auth",
          token_uri: "https://oauth2.googleapis.com/token",
          auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
          client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/vertex-ai.iam.gserviceaccount.com"
        }
      end

      before do
        stub_application_setting(tofa_credentials: credentials.to_json)

        stub_request(:post, "https://www.googleapis.com/oauth2/v4/token").to_return(
          status: 200,
          headers: { 'content-type' => 'application/json; charset=utf-8' },
          body: {
            access_token: access_token,
            expires_in: 3600,
            scope: "https://www.googleapis.com/auth/cloud-platform",
            token_type: "Bearer"
          }.to_json
        ).times(1)
      end

      it 'generates a new token' do
        expect(subject.access_token).to eql(access_token)
      end
    end
  end

  describe '#host' do
    let(:host) { "example-#{SecureRandom.hex(8)}.com" }

    before do
      stub_application_setting(tofa_host: host)
    end

    it { expect(configuration.host).to eql(host) }
  end

  describe '#url' do
    let(:host) { "example-#{SecureRandom.hex(8)}.com" }
    let(:url) { "https://#{host}/api" }

    before do
      stub_application_setting(tofa_url: url)
    end

    it { expect(configuration.url).to eql(url) }
  end
end
