# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Options, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  subject(:options) { described_class.new }

  describe '#chat' do
    it 'returns a hash with the expected keys' do
      result = options.chat(content: 'hello')

      expect(result).to eq({
        model: 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: 'hello' }],
        temperature: 0.7
      })
    end
  end

  describe '#messages_chat' do
    context 'when all messages have valid roles' do
      it 'returns a hash with the expected keys' do
        messages = [
          { role: 'user', content: 'hello user' },
          { role: 'assistant', content: 'hello assistant' }
        ]
        result = options.messages_chat(messages: messages)

        expect(result).to eq({
          model: 'gpt-3.5-turbo',
          messages: [{
            role: 'user',
            content: 'hello user'
          }, {
            role: 'assistant',
            content: 'hello assistant'
          }],
          temperature: 0.7
        })
      end
    end

    context 'when some messages have invalid roles' do
      it 'raises an ArgumentError' do
        messages = [
          { role: 'user', content: 'hello' },
          { role: 'invalid', content: 'hello 2' }
        ]

        expect { options.messages_chat(messages: messages) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#completions' do
    it 'returns a hash with the expected keys' do
      result = options.completions(prompt: 'hello', max_tokens: 10)

      expect(result).to eq({
        model: 'text-davinci-003',
        prompt: 'hello',
        max_tokens: 10
      })
    end
  end

  describe '#edits' do
    it 'returns a hash with the expected keys' do
      result = options.edits(input: 'hello', instruction: 'capitalize')

      expect(result).to eq({
        model: 'text-davinci-edit-001',
        input: 'hello',
        instruction: 'capitalize'
      })
    end
  end

  describe '#embeddings' do
    it 'returns a hash with the expected keys' do
      result = options.embeddings(input: 'hello')

      expect(result).to eq({
        model: 'text-embedding-ada-002',
        input: 'hello'
      })
    end
  end

  describe '#moderations' do
    it 'returns a hash with the expected keys' do
      result = options.moderations(input: 'hello')

      expect(result).to eq({
        model: 'text-moderation-latest',
        input: 'hello'
      })
    end
  end
end
