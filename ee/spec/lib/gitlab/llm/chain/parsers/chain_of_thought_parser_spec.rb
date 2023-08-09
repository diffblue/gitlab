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
      shared_examples 'parses instructions' do
        it 'parses multiline instructions' do
          parser.parse

          expect(parser.thought).to include('This is a multi')
          expect(parser.thought).to include('line thought')
          expect(parser.final_answer).to include('This is a final')
          expect(parser.final_answer).to include('multi line')
          expect(parser.final_answer).to include('answer')
        end
      end

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

      it_behaves_like 'parses instructions'

      context 'when instructions start without whitespaces' do
        let(:output) do
          <<-OUTPUT
          Thought:This is a multi
                   line thought
          Action:This is an action
          Action Input:This is an action input
          Final Answer:This is a final
                        multi line
                        answer
          OUTPUT
        end

        it_behaves_like 'parses instructions'
      end

      context 'when final answer starts on new line and without whitespace' do
        let(:output) do
          <<-OUTPUT
          Thought: This is a multi
                   line thought
          Action: This is an action
          Action Input: This is an action input
          Final Answer:
                        This is a final
                        multi line
                        answer
          OUTPUT
        end

        it_behaves_like 'parses instructions'
      end
    end

    describe 'thought' do
      let(:output) do
        <<-OUTPUT
          something else
          Thought: Thought: Thought: thought
          Action: This is an action
        OUTPUT
      end

      context 'when thought is prefixed with Thought:' do
        it 'removes the prefix' do
          parser.parse

          expect(parser.thought).to eq('thought')
        end
      end
    end

    describe 'action input' do
      context 'when Observation stop word is present' do
        let(:output) do
          <<-OUTPUT
            Action Input: This is an action input
            Observation: this is an observation
          OUTPUT
        end

        it 'returns action input before Observation stop word' do
          parser.parse

          expect(parser.action_input).to eq('This is an action input')
        end
      end

      context 'when Final Answer stop word is present' do
        let(:output) do
          <<-OUTPUT
            Action Input: This is an action input
            Final Answer: this is a final answer
          OUTPUT
        end

        it 'returns action input before Final Answer stop word' do
          parser.parse

          expect(parser.action_input).to eq('This is an action input')
        end
      end

      context 'when none of the stop words are present' do
        let(:output) do
          <<-OUTPUT
            Action Input: This is an action input
          OUTPUT
        end

        it 'returns action input' do
          parser.parse

          expect(parser.action_input).to eq('This is an action input')
        end
      end
    end

    describe 'final answer' do
      context 'when no keyword is present' do
        let(:output) do
          <<-OUTPUT
            Some unformatted answer
          OUTPUT
        end

        it 'returns answer as final' do
          parser.parse

          expect(parser.final_answer).to eq('Some unformatted answer')
        end
      end

      context 'when action is DirectAnswer' do
        let(:output) do
          <<~OUTPUT
            Action: DirectAnswer
            Final Answer: Some answer
          OUTPUT
        end

        it 'parses action and sets answer as final' do
          parser.parse

          expect(parser.action).to eq('DirectAnswer')
          expect(parser.final_answer).to eq('Some answer')
        end
      end

      context 'when action is DirectAnswer followed by unformatted answer' do
        let(:output) do
          <<~OUTPUT
            Action: DirectAnswer
            Some answer
          OUTPUT
        end

        it 'returns unformatted answer as final' do
          parser.parse

          expect(parser.action).to be_nil
          expect(parser.final_answer).to eq('Some answer')
        end
      end
    end
  end
end
