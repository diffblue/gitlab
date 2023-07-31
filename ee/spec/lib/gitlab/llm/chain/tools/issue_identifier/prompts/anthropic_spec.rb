# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::IssueIdentifier::Prompts::Anthropic, feature_category: :shared do
  describe '.prompt' do
    it 'returns prompt' do
      options = {
        input: 'foo?',
        suggestions: "some suggestions"
      }
      prompt = described_class.prompt(options)[:prompt]

      expect(prompt).to include('Human:')
      expect(prompt).to include('Assistant:')
      expect(prompt).to include("\"ResourceIdentifierType\": \"")
      expect(prompt).to include('some suggestions')
      expect(prompt).to include('foo?')
      expect(prompt).to include('You can fetch information about a resource called: an issue.')
    end
  end
end
