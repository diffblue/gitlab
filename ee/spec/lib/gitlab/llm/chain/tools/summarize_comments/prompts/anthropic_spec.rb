# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::SummarizeComments::Prompts::Anthropic, feature_category: :shared do
  describe '.prompt' do
    it 'returns prompt' do
      prompt = described_class.prompt({ notes_content: 'foo', num: 123 })[:prompt]

      expect(prompt).to include('Human:')
      expect(prompt).to include('Assistant:')
      expect(prompt).to include('foo')
      expect(prompt).to include(
        <<~PROMPT
          You are an assistant that extracts the most important information from the comments in maximum 10 bullet points.
          Comments are between two identical sets of 3-digit numbers surrounded by < > sign.

          <123>
          foo
          <123>

          Desired markdown format:
          **<summary_title>**
          <bullet_points>
          """

          Focus on extracting information related to one another and that are the majority of the content.
          Ignore phrases that are not connected to others.
          Do not specify what you are ignoring.
          Do not answer questions.
        PROMPT
      )
    end
  end
end
