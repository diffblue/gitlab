# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Llm::Chain::StreamedAnswer, feature_category: :duo_chat do
  let(:input) do
    <<-INPUT
      Thought: thought
      Action: IssueIdentifier
      Action Input: Bar
    INPUT
  end

  describe '#next_chunk' do
    let(:streamed_answer) { described_class.new }

    context 'when stream is empty' do
      it 'returns nil' do
        expect(streamed_answer.next_chunk("")).to be_nil
      end
    end

    context 'when stream does not contain the final answer' do
      it 'returns nil' do
        expect(streamed_answer.next_chunk("Some")).to be_nil
        expect(streamed_answer.next_chunk("Content")).to be_nil
      end
    end

    context 'when receiving thoughts and actions' do
      it 'only returns the final answer', :aggregate_failures do
        expect(streamed_answer.next_chunk("Thought: thought\n")).to be_nil
        expect(streamed_answer.next_chunk("Action: IssueIdentifier\n")).to be_nil
        expect(streamed_answer.next_chunk("Final Answer: Hello")).to eq({ id: 1, content: "Hello" })
      end
    end

    context 'when receiving a final answer split up in multiple tokens', :aggregate_failures do
      it 'returns the final answer once it is ready', :aggregate_failures do
        expect(streamed_answer.next_chunk("Final Answer")).to be_nil
        expect(streamed_answer.next_chunk(": ")).to be_nil
        expect(streamed_answer.next_chunk("Hello")).to eq({ id: 1, content: "Hello" })
        expect(streamed_answer.next_chunk(" ")).to eq({ id: 2, content: " " })
      end
    end
  end
end
