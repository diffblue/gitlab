# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Anthropic::Client, feature_category: :shared do
  include StubRequests

  let_it_be(:user) { create(:user) }

  let(:api_key) { 'api-key' }
  let(:options) { {} }

  let(:expected_request_headers) do
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'x-api-key' => api_key
    }
  end

  let(:expected_request_body) do
    {
      prompt: 'anything',
      model: described_class::DEFAULT_MODEL,
      max_tokens_to_sample: described_class::DEFAULT_MAX_TOKENS,
      temperature: described_class::DEFAULT_TEMPERATURE
    }
  end

  let(:expected_response) do
    {
      'completion' => 'Response',
      'stop' => nil,
      'stop_reason' => 'max_tokens',
      'truncated' => false,
      'log_id' => 'b454d92a4e108ab78dcccbcc6c83f7ba',
      'model' => 'claude-v1.3',
      'exception' => nil
    }
  end

  before do
    stub_application_setting(anthropic_api_key: api_key)
    stub_full_request("#{described_class::URL}/v1/complete", method: :post)
      .with(
        body: expected_request_body,
        headers: expected_request_headers
      )
      .to_return(
        status: 200,
        body: expected_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '#complete' do
    subject(:complete) { described_class.new(user).complete(prompt: 'anything', **options) }

    context 'when feature flag and API key is set' do
      it 'returns response' do
        expect(complete.parsed_response).to eq(expected_response)
      end
    end

    context 'when using options' do
      let(:options) { { temperature: 0.1 } }

      let(:expected_request_body) do
        {
          prompt: 'anything',
          model: described_class::DEFAULT_MODEL,
          max_tokens_to_sample: described_class::DEFAULT_MAX_TOKENS,
          temperature: options[:temperature]
        }
      end

      it 'returns response' do
        expect(complete.parsed_response).to eq(expected_response)
      end
    end

    context 'when the API key is not present' do
      let(:api_key) { nil }

      it { is_expected.to be_nil }
    end
  end
end
