# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Answer, feature_category: :shared do
  let(:context) { instance_double(Gitlab::Llm::Chain::GitlabContext) }
  let(:tools) { [Gitlab::Llm::Chain::Tools::IssueIdentifier] }
  let(:tool_double) { instance_double(Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor) }

  let(:input) do
    <<-INPUT
      Thought: thought
      Action: IssueIdentifier
      Action Input: Bar
    INPUT
  end

  describe '.from_response' do
    subject(:answer) { described_class.from_response(response_body: input, tools: tools, context: context) }

    before do
      allow(Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor).to receive(:new).and_return(tool_double)
    end

    it 'returns intermediate answer with parsed values and a tool' do
      expect(answer.is_final?).to eq(false)
      expect(answer.tool::NAME).to eq('IssueIdentifier')
    end

    context 'when parsed response is final' do
      it 'returns final answer' do
        allow_next_instance_of(Gitlab::Llm::Chain::Parsers::ChainOfThoughtParser) do |parser|
          allow(parser).to receive(:final_answer).and_return(true)
        end

        expect(answer.is_final?).to eq(true)
      end
    end

    context 'when tool is nil' do
      let(:input) do
        <<-INPUT
          Thought: thought
          Action: Nil
          Action Input: Bar
        INPUT
      end

      it 'returns final answer with default response' do
        expect(answer.is_final?).to eq(true)
        expect(answer.content).to eq(described_class.default_final_message)
      end
    end

    context 'when response is empty' do
      let(:input) { '' }

      it 'returns final answer with default response' do
        expect(answer.is_final?).to eq(true)
        expect(answer.content).to eq(described_class.default_final_message)
      end
    end

    context 'when tool does not contain any of expected keyword' do
      let(:input) { 'Here is my freestyle answer.' }

      it 'returns final answer with default response' do
        expect(answer.is_final?).to eq(true)
        expect(answer.content).to eq(input)
      end
    end
  end
end
