# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Requests::Anthropic, feature_category: :shared do
  describe 'initializer' do
    it 'initializes the anthropic client' do
      request = described_class.new(double)

      expect(request.ai_client.class).to eq(::Gitlab::Llm::Anthropic::Client)
    end
  end

  describe 'request' do
    it 'calls the anthropic completion endpoint' do
      request = described_class.new(double)
      ai_client = double
      allow(request).to receive(:ai_client).and_return(ai_client)
      expect(ai_client).to receive(:complete)

      request.request("some user request")
    end
  end
end
