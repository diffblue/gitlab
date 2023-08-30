# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Requests::Anthropic, feature_category: :duo_chat do
  let_it_be(:user) { build(:user) }

  describe 'initializer' do
    it 'initializes the anthropic client' do
      request = described_class.new(user)

      expect(request.ai_client.class).to eq(::Gitlab::Llm::Anthropic::Client)
    end
  end

  describe '#request' do
    subject(:request) { instance.request(params) }

    let(:instance) { described_class.new(user) }
    let(:logger) { instance_double(Gitlab::Llm::Logger) }
    let(:ai_client) { double }
    let(:response) { { "completion" => "Hello World " } }
    let(:expected_params) do
      {
        prompt: "some user request",
        temperature: 0.1,
        stop_sequences: ["\n\nHuman", "Observation:"]
      }
    end

    before do
      allow(Gitlab::Llm::Logger).to receive(:build).and_return(logger)
      allow(instance).to receive(:ai_client).and_return(ai_client)
    end

    context 'when streaming is disabled' do
      before do
        stub_feature_flags(stream_gitlab_duo: false)
      end

      context 'with prompt and options' do
        let(:params) { { prompt: "some user request", options: { max_tokens: 4000 } } }

        it 'calls the anthropic completion endpoint, parses response and strips it' do
          expect(ai_client).to receive(:complete).with(expected_params.merge({ max_tokens: 4000 })).and_return(response)

          expect(request).to eq("Hello World")
        end
      end

      context 'when options are not present' do
        let(:params) { { prompt: "some user request" } }

        it 'calls the anthropic completion endpoint' do
          expect(ai_client).to receive(:complete).with(expected_params)

          request
        end
      end
    end

    context 'when streaming is enabled' do
      before do
        stub_feature_flags(stream_gitlab_duo: true)
      end

      context 'with prompt and options' do
        let(:params) { { prompt: "some user request", options: { max_tokens: 4000 } } }

        it 'calls the anthropic streaming endpoint and yields response without stripping it' do
          expect(ai_client).to receive(:stream).with(expected_params.merge({ max_tokens: 4000 })).and_yield(response)

          expect { |b| instance.request(params, &b) }.to yield_with_args(
            "Hello World "
          )
        end
      end

      context 'when options are not present' do
        let(:params) { { prompt: "some user request" } }

        it 'calls the anthropic streaming endpoint' do
          expect(ai_client).to receive(:stream).with(expected_params)

          request
        end
      end

      context 'when stream errors' do
        let(:params) { { prompt: "some user request" } }
        let(:response) { { "error" => { "type" => "overload_error", message: "Overloaded" } } }

        it 'logs the error' do
          expect(ai_client).to receive(:stream).with(expected_params).and_yield(response)
          expect(logger).to receive(:info).with(hash_including(message: "Streaming error", error: response["error"]))

          request
        end
      end
    end
  end
end
