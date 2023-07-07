# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::Templates::ExplainCode, feature_category: :source_code_management do
  let(:messages) do
    [
      {
        'role' => 'system',
        'content' => 'You are a knowledgeable assistant explaining to an engineer'
      }, {
        'role' => 'user',
        'content' => 'some initial request'
      }, {
        'role' => 'assistant',
        'content' => 'some response'
      }, {
        'role' => 'user',
        'content' => 'consequent request'
      }
    ]
  end

  describe '.get_options' do
    it 'returns correct parameters' do
      expect(described_class.get_options(messages)).to eq({
        instances: [
          messages: [{
            'author' => 'user',
            'content' => "You are a knowledgeable assistant explaining to an engineer\nsome initial request"
          }, {
            'author' => 'content',
            'content' => 'some response'
          }, {
            'author' => 'user',
            'content' => 'consequent request'
          }]
        ],
        parameters: {
          maxOutputTokens: 300,
          temperature: 0.3,
          topK: 40,
          topP: 0.95
        }
      })
    end
  end
end
