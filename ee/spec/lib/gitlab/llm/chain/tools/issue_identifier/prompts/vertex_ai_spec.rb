# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::IssueIdentifier::Prompts::VertexAi, feature_category: :shared do
  describe '.prompt' do
    it 'returns prompt' do
      options = {
        suggestions: "some suggestions",
        input: 'foo?'
      }
      prompt = described_class.prompt(options)

      expect(prompt).to include('some suggestions')
      expect(prompt).to include('foo?')
      expect(prompt).to include('You can identify an issue or fetch information about an issue.')
    end
  end
end
