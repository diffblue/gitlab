# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Requests::Anthropic, feature_category: :shared do
  describe 'initializer' do
    it 'initializes the anthropic client' do
      request = described_class.new(double)

      expect(request.ai_client.class).to eq(::Gitlab::Llm::Anthropic::Client)
    end
  end

  describe '#request' do
    subject(:request) { instance.request(params) }

    let(:instance) { described_class.new(double) }
    let(:ai_client) { double }
    let(:expected_params) do
      {
        prompt: "some user request",
        temperature: 0.2,
        stop_sequences: ["\n\nHuman", "Observation:"]
      }
    end

    before do
      allow(instance).to receive(:ai_client).and_return(ai_client)
    end

    context 'with prompt and options' do
      let(:params) { { prompt: "some user request", options: { max_tokens: 4000 } } }

      it 'calls the anthropic completion endpoint' do
        expect(ai_client).to receive(:complete).with(expected_params.merge({ max_tokens: 4000 }))

        request
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
end
