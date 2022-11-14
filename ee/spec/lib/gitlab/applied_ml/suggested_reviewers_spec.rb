# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AppliedMl::SuggestedReviewers, feature_category: :workflow_automation do
  let(:secret) { SecureRandom.random_bytes(described_class::SECRET_LENGTH) }

  before do
    allow(described_class).to receive(:secret).and_return(secret)
  end

  describe '.verify_api_request' do
    let(:payload) { { 'iss' => described_class::JWT_ISSUER } }

    subject(:decoded_token) do
      described_class.verify_api_request(headers)
    end

    context 'when header is not set' do
      let(:headers) { {} }

      it { is_expected.to be_nil }
    end

    context 'when token is encoded with a wrong secret' do
      let(:headers) do
        encoded_token = JWT.encode(payload, 'wrongsecret', 'HS256')
        { described_class::INTERNAL_API_REQUEST_HEADER => encoded_token }
      end

      it { is_expected.to be_nil }
    end

    context 'when header is included a token encoded with a correct secret' do
      let(:headers) do
        encoded_token = JWT.encode(payload, secret, 'HS256')
        { described_class::INTERNAL_API_REQUEST_HEADER => encoded_token }
      end

      it { is_expected.to match_array([{ "iss" => described_class::JWT_ISSUER }, { "alg" => "HS256" }]) }
    end
  end

  describe '.ensure_secret!' do
    context 'when environment value is not set' do
      before do
        stub_env(described_class::SECRET_NAME, nil)
      end

      it 'raises an error' do
        expect { described_class.ensure_secret! }.to raise_error(
          Gitlab::AppliedMl::Errors::ConfigurationError,
          'Variable GITLAB_SUGGESTED_REVIEWERS_API_SECRET is missing'
        )
      end
    end

    context 'when secret is not correct length' do
      before do
        stub_env(described_class::SECRET_NAME, 'abcd1234')
      end

      it 'raises an error' do
        expect { described_class.ensure_secret! }.to raise_error(
          Gitlab::AppliedMl::Errors::ConfigurationError,
          "Secret must contain #{described_class::SECRET_LENGTH} bytes"
        )
      end
    end

    context 'when secret is valid' do
      before do
        stub_env(described_class::SECRET_NAME, secret)
      end

      it 'returns the secret' do
        expect(described_class.ensure_secret!).to eq(secret)
      end
    end
  end
end
