# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::JsonReader::Prompts::Anthropic, feature_category: :shared do
  describe '.prompt' do
    it 'returns prompt' do
      options = {
        suggestions: "some suggestions",
        input: 'foo?'
      }
      prompt = described_class.prompt(options)[:prompt]

      expect(prompt).to include('Human:')
      expect(prompt).to include('Assistant:')
      expect(prompt).to include('Thought:')
      expect(prompt).to include('some suggestions')
      expect(prompt).to include('foo?')
      expect(prompt).to include('You are an agent designed to interact with JSON.')
    end
  end
end
