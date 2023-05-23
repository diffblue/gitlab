# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Answer, feature_category: :shared do
  let(:context) { instance_double(Gitlab::Llm::Chain::GitlabContext) }
  let(:tool_double) do
    instance_double(Gitlab::Llm::Chain::Tools::Tool, name: 'Foo', description: 'Bar')
  end

  let(:input) do
    <<-INPUT
      Thought: thought
      Action: Foo
      Action Input: Bar
    INPUT
  end

  describe '.from_response' do
    subject(:answer) { described_class.from_response(response_body: input, tools: [tool_double], context: context) }

    it 'returns intermediate answer with parsed values and a tool' do
      expect(answer.is_final?).to eq(false)
      expect(answer.tool.name).to eq('Foo')
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
        expect(answer.content).to eq(described_class.default_final_answer)
      end
    end
  end
end
