# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Agents::ZeroShot::Executor, feature_category: :shared do
  let(:input) { 'foo' }
  let(:context) { instance_double(Gitlab::Llm::Chain::GitlabContext) }
  let(:ai_request_double) { instance_double(Gitlab::Llm::Chain::Requests::Anthropic) }
  let(:tool_answer) { instance_double(Gitlab::Llm::Chain::Answer, is_final?: false, content: 'Bar') }
  let(:tool_double) { instance_double(Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor) }
  let(:tools) { [Gitlab::Llm::Chain::Tools::IssueIdentifier] }
  let(:response_double) { "I know the final answer\nFinal Answer: FooBar" }

  subject(:agent) { described_class.new(user_input: input, tools: tools, context: context) }

  describe '#execute' do
    before do
      allow(context).to receive(:ai_request).and_return(ai_request_double)
      allow(ai_request_double).to receive(:request).and_return(response_double)
      allow(tool_double).to receive(:execute).and_return(tool_answer)
      allow_next_instance_of(Gitlab::Llm::Chain::Answer) do |answer|
        allow(answer).to receive(:tool).and_return(Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor)
      end
      allow(Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor)
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
        stub_const("#{described_class.name}::MAX_ITERATIONS", 2)

        allow(agent).to receive(:request).and_return("Action: IssueIdentifier\nActionInput: #3")
        expect(agent).to receive(:request).twice.times

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
