# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::ExplainCode::Prompts::VertexAi, feature_category: :shared do
  describe '.prompt' do
    it 'returns prompt' do
      prompt = described_class.prompt({ input: 'foo' })[:prompt]

      expect(prompt).to include('foo')
      expect(prompt).to include(
        <<~PROMPT
          You are a software developer.
          You can explain code snippets.
          The code can be in any programming language.
          Explain the code below.
        PROMPT
      )
    end
  end
end
