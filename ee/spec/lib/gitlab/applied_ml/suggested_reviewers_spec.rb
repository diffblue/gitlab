# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AppliedMl::SuggestedReviewers, feature_category: :code_review_workflow do
  let(:secret) { SecureRandom.random_bytes(described_class::SECRET_LENGTH) }

  before do
    allow(described_class).to receive(:secret).and_return(secret)
  end

  describe '.verify_api_request' do
    let(:iat) { 1.minute.ago.to_i }
    let(:payload) { { 'iss' => described_class::JWT_ISSUER, 'iat' => iat } }

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

      it { is_expected.to match_array([{ 'iss' => described_class::JWT_ISSUER, 'iat' => iat }, { 'alg' => 'HS256' }]) }
    end
  end

  describe '.secret_path' do
    it 'returns default gitlab config' do
      expect(described_class.secret_path).to eq(Gitlab.config.suggested_reviewers.secret_file)
    end
  end

  describe '.ensure_secret!' do
    context 'when secret file exists' do
      before do
        allow(File).to receive(:exist?).with(Gitlab.config.suggested_reviewers.secret_file).and_return(true)
      end

      it 'does not call write_secret' do
        expect(described_class).not_to receive(:write_secret)

        described_class.ensure_secret!
      end
    end

    context 'when secret file does not exist' do
      before do
        allow(File).to receive(:exist?).with(Gitlab.config.suggested_reviewers.secret_file).and_return(false)
      end

      it 'calls write_secret' do
        expect(described_class).to receive(:write_secret)

        described_class.ensure_secret!
      end
    end
  end
end
