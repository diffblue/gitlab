# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::Client, feature_category: :not_owned do # rubocop: disable  RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }

  let(:access_token) { SecureRandom.uuid }

  let(:configuration) do
    instance_double(
      ::Gitlab::Llm::VertexAi::Configuration,
      access_token: access_token,
      host: "example.com",
      url: "https://example.com/api"
    )
  end

  subject(:client) { described_class.new(user, configuration) }

  describe "#chat" do
    subject(:response) { client.chat(content: "Hello, world!") }

    let(:successful_response) do
      {
        predictions: [
          candidates: [
            {
              content: "Sure, ..."
            }
          ]
        ]
      }
    end

    context 'when a successful response is returned from the API' do
      before do
        request_body = {
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
            temperature: described_class::DEFAULT_TEMPERATURE
          }
        }

        stub_request(:post, "https://example.com/api").with(
          headers: {
            accept: 'application/json',
            'Authorization' => "Bearer #{access_token}",
            'Content-Type' => 'application/json',
            'Host' => 'example.com'
          },
          body: request_body.to_json
        ).to_return(status: 200, body: successful_response.to_json)
      end

      it 'returns the response' do
        expect(response).to be_present
        expect(::Gitlab::Json.parse(response.body, symbolize_names: true)).to match(hash_including(
          {
            predictions: [
              candidates: [
                {
                  content: "Sure, ..."
                }
              ]
            ]
          }
        ))
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
        stub_request(:post, "https://example.com/api")
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
end
