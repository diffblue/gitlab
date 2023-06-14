# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Agents::ZeroShot::Executor, :clean_gitlab_redis_chat, feature_category: :shared do
  let(:input) { 'foo' }
  let(:user) { create(:user) }
  let(:context) { instance_double(Gitlab::Llm::Chain::GitlabContext, current_user: user) }
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

        allow(agent).to receive(:request).and_return("Action: IssueIdentifier\nAction Input: #3")
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

  describe '#prompt' do
    before do
      allow(agent).to receive(:provider_prompt_class)
        .and_return(Gitlab::Llm::Chain::Agents::ZeroShot::Prompts::Anthropic)

      Gitlab::Llm::Cache.new(user).add(request_id: 'uuid1', role: 'user', content: 'question 1')
      Gitlab::Llm::Cache.new(user).add(request_id: 'uuid1', role: 'assistant', content: 'response 1')
      # this should be ignored because response contains an error
      Gitlab::Llm::Cache.new(user).add(request_id: 'uuid2', role: 'user', content: 'question 2')
      Gitlab::Llm::Cache.new(user)
        .add(request_id: 'uuid2', role: 'assistant', content: 'response 2', errors: ['error'])
      # this should be ignored because it doesn't contain response
      Gitlab::Llm::Cache.new(user).add(request_id: 'uuid3', role: 'user', content: 'question 3')
      Gitlab::Llm::Cache.new(user).add(request_id: 'uuid4', role: 'user', content: 'question 4')
      Gitlab::Llm::Cache.new(user).add(request_id: 'uuid4', role: 'assistant', content: 'response 4')
    end

    it 'includes cleaned chat in prompt options' do
      expected_chat = [
        an_object_having_attributes(content: 'question 1'),
        an_object_having_attributes(content: 'response 1'),
        an_object_having_attributes(content: 'question 4'),
        an_object_having_attributes(content: 'response 4')
      ]
      expect(Gitlab::Llm::Chain::Agents::ZeroShot::Prompts::Anthropic)
        .to receive(:prompt).once.with(a_hash_including(conversation: expected_chat))

      agent.prompt
    end

    context 'when ai_chat_history_context is disabled' do
      before do
        stub_feature_flags(ai_chat_history_context: false)
      end

      it 'includes an ampty chat' do
        expect(Gitlab::Llm::Chain::Agents::ZeroShot::Prompts::Anthropic)
          .to receive(:prompt).once.with(a_hash_including(conversation: []))

        agent.prompt
      end
    end
  end
end
