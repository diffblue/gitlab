# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Agents::ZeroShot, feature_category: :shared do
  let(:input) { 'foo' }
  let(:context) { instance_double(Gitlab::Llm::Chain::GitlabContext) }
  let(:client_double) { instance_double(Gitlab::Llm::VertexAi::Client) }
  let(:tool_answer) { instance_double(Gitlab::Llm::Chain::Answer, is_final?: false, content: 'Bar') }
  let(:tool_double) { instance_double(Gitlab::Llm::Chain::Tools::Tool) }
  let(:tools) { [Gitlab::Llm::Chain::Tools::Tool] }
  let(:response_double_1) do
    { 'predictions' => [{ 'content' => "I need to execute tool Foo\nAction: Base Tool\nAction Input: Foo\n" }] }
  end

  let(:response_double_2) do
    { 'predictions' => [{ 'content' => "I know the final answer\nFinal Answer: FooBar" }] }
  end

  subject(:agent) { described_class.new(user_input: input, tools: tools, context: context) }

  describe '#execute' do
    before do
      allow(context).to receive(:ai_client).and_return(client_double)
      allow(client_double).to receive(:text).and_return(response_double_1, response_double_2)
      allow(tool_double).to receive(:execute).and_return(tool_answer)
      allow_next_instance_of(Gitlab::Llm::Chain::Answer) do |answer|
        allow(answer).to receive(:tool).and_return(Gitlab::Llm::Chain::Tools::Tool)
      end
      allow(Gitlab::Llm::Chain::Tools::Tool)
        .to receive(:new)
        .with(context: context, options: anything)
        .and_return(tool_double)
    end

    it 'executes associated tools and adds observations during the execution' do
      answer = agent.execute

      expect(answer.is_final).to eq(true)
      expect(answer.content).to include('FooBar')
    end

    context 'when max iterations reached' do
      it 'returns' do
        stub_const("#{described_class.name}::MAX_ITERATIONS", 0)

        expect(agent).not_to receive(:request)

        answer = agent.execute

        expect(answer.is_final?).to eq(true)
        expect(answer.content).to include(Gitlab::Llm::Chain::Answer.default_final_answer)
      end
    end

    context 'when answer is final' do
      let(:response_content_1) { "Thought: I know final answer\nFinal Answer: Foo" }

      it 'returns final answer' do
        answer = agent.execute

        expect(answer.is_final?).to eq(true)
      end
    end

    context 'when tool answer if final' do
      let(:tool_answer) { instance_double(Gitlab::Llm::Chain::Answer, is_final?: true) }

      it 'returns final answer' do
        answer = agent.execute

        expect(answer.is_final?).to eq(true)
      end
    end
  end
end
