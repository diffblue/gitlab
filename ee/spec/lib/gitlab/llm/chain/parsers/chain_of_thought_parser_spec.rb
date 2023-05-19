# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Parsers::ChainOfThoughtParser, feature_category: :shared do
  let(:output) do
    <<-OUTPUT
      Thought: This is a thought
      Action: This is an action
      Action Input: This is an action input
      Final Answer: This is a final answer
    OUTPUT
  end

  subject(:parser) { described_class.new(output: output) }

  describe '#parse' do
    it 'parses input for instructions' do
      expect(Gitlab::Llm::Chain::Utils::TextProcessing)
        .to receive(:text_before_stop_word)
        .with(output)
        .and_call_original

      parser.parse

      expect(parser.action).to eq('This is an action')
      expect(parser.action_input).to eq('This is an action input')
      expect(parser.thought).to eq('This is a thought')
      expect(parser.final_answer).to eq('This is a final answer')
    end

    context 'when observation stop word is present' do
      let(:output) do
        <<-OUTPUT
          Thought: This is a thought
          Action: This is an action
          Action Input: This is an action input
          Observation: this is an observation
          Final Answer: This is a final answer
        OUTPUT
      end

      it 'only parses input above the stop word' do
        parser.parse

        expect(parser.action).to eq('This is an action')
        expect(parser.final_answer).to be_nil
      end
    end

    context 'when input has multiline instructions' do
      let(:output) do
        <<-OUTPUT
          Thought: This is a multi
                   line thought
          Action: This is an action
          Action Input: This is an action input
          Final Answer: This is a final
                        multi line
                        answer
        OUTPUT
      end

      it 'parses multiline instructions' do
        parser.parse

        expect(parser.thought).to include('This is a multi')
        expect(parser.thought).to include('line thought')
        expect(parser.final_answer).to include('This is a final')
        expect(parser.final_answer).to include('multi line')
        expect(parser.final_answer).to include('answer')
      end
    end
  end
end
