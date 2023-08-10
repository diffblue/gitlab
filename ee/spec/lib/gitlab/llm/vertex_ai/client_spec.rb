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

  let(:response_headers) { { 'Content-Type' => 'application/json' } }

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

  let(:client) { described_class.new(user) }

  shared_examples 'forwarding the request correctly' do
    let(:successful_response) do
      { safetyAttributes: { blocked: false }, predictions: [candidates: [{ content: "Sure, ..." }]] }
    end

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
        ).to_return(status: 200, body: successful_response.to_json, headers: response_headers)
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
          .to_return(status: 429, body: too_many_requests_response.to_json, headers: response_headers)
          .then.to_return(status: 429, body: too_many_requests_response.to_json, headers: response_headers)
          .then.to_return(status: 200, body: successful_response.to_json, headers: response_headers)

        allow(client).to receive(:sleep).and_return(nil)
      end

      it 'retries the request' do
        expect(response).to be_present
        expect(response.code).to eq(200)
      end
    end

    context 'when a content blocked response is returned from the API' do
      let(:content_blocked_response) do
        { safetyAttributes: { blocked: true }, predictions: [candidates: [{ content: "I am just an AI..." }]] }
      end

      context 'and retry_content_blocked_requests is true' do
        let(:client) { described_class.new(user, retry_content_blocked_requests: true) }

        before do
          stub_request(:post, url)
            .to_return(status: 200, body: content_blocked_response.to_json, headers: response_headers)
            .then.to_return(status: 200, body: successful_response.to_json, headers: response_headers)

          allow(client).to receive(:sleep).and_return(nil)
        end

        it 'retries the request' do
          expect(response).to be_present
          expect(response.code).to eq(200)
          expect(client).to have_received(:sleep)
        end
      end

      context 'and retry_content_blocked_requests is false' do
        let(:client) { described_class.new(user, retry_content_blocked_requests: false) }

        before do
          stub_request(:post, url)
            .to_return(status: 200, body: content_blocked_response.to_json, headers: response_headers)

          allow(client).to receive(:sleep).and_return(nil)
        end

        it 'retries the request' do
          expect(response).to be_present
          expect(response.code).to eq(200)
          expect(client).not_to have_received(:sleep)
        end
      end
    end
  end

  describe '#chat' do
    subject(:response) { client.chat(content: 'anything', **options) }

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

    subject(:response) { client.messages_chat(content: messages, **options) }

    it_behaves_like 'forwarding the request correctly'
  end

  describe '#text' do
    subject(:response) { client.text(content: 'anything', **options) }

    it_behaves_like 'forwarding the request correctly'
  end

  describe '#code' do
    subject(:response) { client.code(content: 'anything', **options) }

    it_behaves_like 'forwarding the request correctly'
  end

  describe '#code_completion' do
    subject(:response) { client.code_completion(content: 'anything', **options) }

    it_behaves_like 'forwarding the request correctly'
  end

  describe '#request' do
    let(:url) { 'https://example.com/api' }
    let(:config) do
      instance_double(
        ::Gitlab::Llm::VertexAi::Configuration,
        headers: {},
        payload: {},
        url: url
      )
    end

    subject { described_class.new(user).text(content: 'anything', **options) }

    before do
      allow(Gitlab::Llm::VertexAi::Configuration).to receive(:new).and_return(config)
      stub_request(:post, url).to_return(status: 200, body: 'some response')
    end

    context 'when measuring request success' do
      let(:client) { :vertex_ai }

      it_behaves_like 'measured Llm request'

      context 'when request raises an exception' do
        before do
          allow(Gitlab::HTTP).to receive(:post).and_raise(StandardError)
        end

        it_behaves_like 'measured Llm request with error'
      end
    end
  end
end
