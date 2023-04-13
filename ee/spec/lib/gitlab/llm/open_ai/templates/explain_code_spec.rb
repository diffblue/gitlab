# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Templates::ExplainCode, feature_category: :source_code_management do
  let(:messages) do
    [{
      role: 'system',
      content: 'You are a knowledgeable assistant explaining to an engineer'
    }]
  end

  describe '.get_options' do
    it 'returns correct parameters' do
      expect(described_class.get_options(messages)).to eq({
        messages: messages,
        max_tokens: 300,
        temperature: 0.3
      })
    end
  end
end
