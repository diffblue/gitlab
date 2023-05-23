# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Agents::ZeroShot, feature_category: :shared do
  let(:input) { 'foo' }
  let(:context) { instance_double(Gitlab::Llm::Chain::GitlabContext) }
  let(:response_content_1) { "I need to execute tool Foo\nAction: Foo\nAction Input: Bar\n" }
  let(:response_content_2) { "I know the final answer\nFinal Answer: FooBar" }
  let(:tool_double) do
    instance_double(Gitlab::Llm::Chain::Tools::Tool, name: 'Foo', description: 'Bar')
  end

  let(:tool_answer) { instance_double(Gitlab::Llm::Chain::Answer, is_final?: false, content: 'Bar') }
  let(:tools) { [tool_double] }

  subject(:agent) { described_class.new(user_input: input, tools: tools, context: context) }

  describe '#execute' do
    before do
      allow(agent).to receive(:request).and_return(response_content_1, response_content_2)
      allow(tool_double).to receive(:execute).with(context, anything).and_return(tool_answer)
      allow_next_instance_of(Gitlab::Llm::Chain::Answer) do |answer|
        allow(answer).to receive(:tool).and_return(tool_double)
      end
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
