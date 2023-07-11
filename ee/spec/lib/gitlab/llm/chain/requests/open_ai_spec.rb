# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Requests::OpenAi, feature_category: :shared do
  describe 'initializer' do
    it 'initializes the openai client' do
      request = described_class.new(double)

      expect(request.ai_client.class).to eq(::Gitlab::Llm::OpenAi::Client)
    end
  end

  describe 'request' do
    it 'calls the openai completions endpoint' do
      request = described_class.new(double)
      ai_client = double
      allow(request).to receive(:ai_client).and_return(ai_client)
      expect(ai_client).to receive(:completions)

      request.request({ prompt: "some user request", options: {} })
    end
  end
end
