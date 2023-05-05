# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::Client, feature_category: :not_owned do # rubocop: disable  RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }

  let(:access_token) { SecureRandom.uuid }
  let(:url) { 'https://example.com/api' }
  let(:host) { 'example.com' }
  let(:options) { {} }
  let(:model_config) do
    instance_double(
      ::Gitlab::Llm::VertexAi::ModelConfigurations::CodeChat,
      url: url,
      host: host,
      payload: request_payload
    )
  end

  let(:headers) do
    {
      accept: 'application/json',
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json',
      'Host' => host
    }
  end

  let(:request_payload) do
    {
      instances: [
        {
          messages: [
            {
              author: "content",
              content: "Hello, world!"
            }
          ]
        }
      ],
      parameters: {
        temperature: Gitlab::Llm::VertexAi::Configuration::DEFAULT_TEMPERATURE
      }
    }
  end

  subject(:client) { described_class.new(user) }

  shared_examples 'forwarding the request correctly' do
    let(:successful_response) { { predictions: [candidates: [{ content: "Sure, ..." }]] } }

    before do
      allow_next_instance_of(Gitlab::Llm::VertexAi::Configuration) do |instance|
        allow(instance).to receive(:model_config).and_return(model_config)
        allow(instance).to receive(:headers).and_return(headers)
        allow(instance).to receive(:access_token).and_return(access_token)
      end
    end

    context 'when a successful response is returned from the API' do
      before do
        stub_request(:post, url).with(
          headers: headers,
          body: request_payload
        ).to_return(status: 200, body: successful_response.to_json)
      end

      it 'returns the response' do
        expect(response).to be_present
        expect(::Gitlab::Json.parse(response.body, symbolize_names: true))
          .to match(hash_including(successful_response))
      end
    end

    context 'when a failed response is returned from the API' do
      let(:too_many_requests_response) do
        {
          error: {
            code: 429,
            message: 'Rate Limit Exceeded',
            status: 'RATE_LIMIT_EXCEEDED',
            details: [
              {
                "@type": 'type.googleapis.com/google.rpc.ErrorInfo',
                reason: 'RATE_LIMIT_EXCEEDED',
                metadata: {
                  service: 'aiplatform.googleapis.com',
                  method: 'google.cloud.aiplatform.v1.PredictionService.Predict'
                }
              }
            ]
          }
        }
      end

      before do
        stub_request(:post, url)
          .to_return(status: 429, body: too_many_requests_response.to_json)
          .then.to_return(status: 429, body: too_many_requests_response.to_json)
          .then.to_return(status: 200, body: successful_response.to_json)

        allow(client).to receive(:sleep).and_return(nil)
      end

      it 'retries the request' do
        expect(response).to be_present
        expect(response.code).to eq(200)
      end
    end
  end

  describe '#chat' do
    subject(:response) { described_class.new(user).chat(content: 'anything', **options) }

    it_behaves_like 'forwarding the request correctly'
  end

  describe '#messages_chat' do
    let(:messages) do
      [
        { author: 'user', content: 'foo' },
        { author: 'content', content: 'bar' },
        { author: 'user', content: 'baz' }
      ]
    end

    subject(:response) { described_class.new(user).messages_chat(content: messages, **options) }

    it_behaves_like 'forwarding the request correctly'
  end

  describe '#text' do
    subject(:response) { described_class.new(user).text(content: 'anything', **options) }

    it_behaves_like 'forwarding the request correctly'
  end

  describe '#code' do
    subject(:response) { described_class.new(user).code(content: 'anything', **options) }

    it_behaves_like 'forwarding the request correctly'
  end
end
