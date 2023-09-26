# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Agents::ZeroShot::Executor, :clean_gitlab_redis_chat, feature_category: :duo_chat do
  include FakeBlobHelpers

  let_it_be(:user) { create(:user) }

  let(:input) { 'foo' }
  let(:ai_request_double) { instance_double(Gitlab::Llm::Chain::Requests::Anthropic) }
  let(:tool_answer) { instance_double(Gitlab::Llm::Chain::Answer, is_final?: false, content: 'Bar', status: :ok) }
  let(:tool_double) { instance_double(Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor) }
  let(:tools) { [Gitlab::Llm::Chain::Tools::IssueIdentifier] }
  let(:extra_resource) { {} }
  let(:response_double) { "I know the final answer\nFinal Answer: FooBar" }
  let(:resource) { user }
  let(:response_service_double) { instance_double(::Gitlab::Llm::ResponseService) }
  let(:stream_response_service_double) { nil }

  let(:context) do
    Gitlab::Llm::Chain::GitlabContext.new(
      current_user: user, container: nil, resource: resource, ai_request: ai_request_double,
      tools_used: [Gitlab::Llm::Chain::Tools::IssueIdentifier, Gitlab::Llm::Chain::Tools::IssueIdentifier],
      extra_resource: extra_resource
    )
  end

  subject(:agent) do
    described_class.new(
      user_input: input,
      tools: tools,
      context: context,
      response_handler: response_service_double,
      stream_response_handler: stream_response_service_double
    )
  end

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

    context 'when streaming is disabled' do
      before do
        stub_feature_flags(stream_gitlab_duo: false)
      end

      it 'executes associated tools and adds observations during the execution' do
        answer = agent.execute

        expect(answer.is_final).to eq(true)
        expect(answer.content).to include('FooBar')
      end

      context 'without final answer' do
        before do
          # just limiting the number of iterations here from 10 to 2
          stub_const("#{described_class.name}::MAX_ITERATIONS", 2)
        end

        it 'executes associated tools and adds observations during the execution' do
          logger = instance_double(Gitlab::Llm::Logger)

          expect(Gitlab::Llm::Logger).to receive(:build).at_least(:once).and_return(logger)
          expect(logger).to receive(:info).with(hash_including(message: "Tool cycling detected")).exactly(2)
          expect(logger).to receive(:info).at_least(:once)
          expect(logger).to receive(:debug).at_least(:once)
          expect(response_service_double).to receive(:execute).at_least(:once)

          allow(agent).to receive(:request).and_return("Action: IssueIdentifier\nAction Input: #3")

          agent.execute
        end

        context 'with the ai_tool_info flag switched off' do
          before do
            stub_feature_flags(ai_tool_info: false)
          end

          it 'does not call response_service' do
            expect(response_service_double).not_to receive(:execute)

            allow(agent).to receive(:request).and_return("Action: IssueIdentifier\nAction Input: #3")

            agent.execute
          end
        end
      end

      context 'when max iterations reached' do
        it 'returns' do
          stub_const("#{described_class.name}::MAX_ITERATIONS", 2)

          allow(agent).to receive(:request).and_return("Action: IssueIdentifier\nAction Input: #3")
          expect(agent).to receive(:request).twice.times
          expect(response_service_double).to receive(:execute).at_least(:once)

          answer = agent.execute

          expect(answer.is_final?).to eq(true)
          expect(answer.content).to include(Gitlab::Llm::Chain::Answer.default_final_message)
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

    context 'when streaming is enabled' do
      let(:stream_response_service_double) { instance_double(::Gitlab::Llm::ResponseService) }

      before do
        stub_feature_flags(stream_gitlab_duo: true)
        allow(ai_request_double).to receive(:request).and_yield("Final Answer:").and_yield("Hello").and_yield(" World")
      end

      it 'streams the final answer' do
        first_response_double = double
        second_response_double = double

        allow(Gitlab::Llm::Chain::PlainResponseModifier).to receive(:new).with("Hello")
          .and_return(first_response_double)

        allow(Gitlab::Llm::Chain::PlainResponseModifier).to receive(:new).with(" World")
          .and_return(second_response_double)

        expect(stream_response_service_double).to receive(:execute).with(
          response: first_response_double,
          options: { cache_response: false, role: ::Gitlab::Llm::ChatMessage::ROLE_ASSISTANT, chunk_id: 1 }
        )
        expect(stream_response_service_double).to receive(:execute).with(
          response: second_response_double,
          options: { cache_response: false, role: ::Gitlab::Llm::ChatMessage::ROLE_ASSISTANT, chunk_id: 2 }
        )

        agent.execute
      end
    end
  end

  describe '#prompt' do
    before do
      allow(agent).to receive(:provider_prompt_class)
                        .and_return(Gitlab::Llm::Chain::Agents::ZeroShot::Prompts::Anthropic)

      Gitlab::Llm::ChatStorage.new(user).add(request_id: 'uuid1', role: 'user', content: 'question 1')
      Gitlab::Llm::ChatStorage.new(user).add(request_id: 'uuid1', role: 'assistant', content: 'response 1')
      # this should be ignored because response contains an error
      Gitlab::Llm::ChatStorage.new(user).add(request_id: 'uuid2', role: 'user', content: 'question 2')
      Gitlab::Llm::ChatStorage.new(user)
                        .add(request_id: 'uuid2', role: 'assistant', content: 'response 2', errors: ['error'])
      # this should be ignored because it doesn't contain response
      Gitlab::Llm::ChatStorage.new(user).add(request_id: 'uuid3', role: 'user', content: 'question 3')

      travel(2.minutes) do
        Gitlab::Llm::ChatStorage.new(user).add(request_id: 'uuid4', role: 'user', content: 'question 4')
      end
      travel(2.minutes) do
        Gitlab::Llm::ChatStorage.new(user).add(request_id: 'uuid5', role: 'user', content: 'question 5')
      end
      travel(3.minutes) do
        Gitlab::Llm::ChatStorage.new(user).add(request_id: 'uuid4', role: 'assistant', content: 'response 4')
      end
      travel(4.minutes) do
        Gitlab::Llm::ChatStorage.new(user).add(request_id: 'uuid5', role: 'assistant', content: 'response 5')
      end
    end

    it 'includes cleaned chat in prompt options with responses reordered to be paired with questions' do
      expected_chat = [
        an_object_having_attributes(content: 'question 1'),
        an_object_having_attributes(content: 'response 1'),
        an_object_having_attributes(content: 'question 4'),
        an_object_having_attributes(content: 'response 4'),
        an_object_having_attributes(content: 'question 5'),
        an_object_having_attributes(content: 'response 5')
      ]
      expect(Gitlab::Llm::Chain::Agents::ZeroShot::Prompts::Anthropic)
        .to receive(:prompt).once.with(a_hash_including(conversation: expected_chat))

      agent.prompt
    end

    it 'includes the prompt' do
      expect(Gitlab::Llm::Chain::Agents::ZeroShot::Prompts::Anthropic)
        .to receive(:prompt).once.with(a_hash_including(prompt_version:
                                                          described_class::PROMPT_TEMPLATE))

      agent.prompt
    end

    context 'when resource is a blob' do
      let(:project) { build(:project) }
      let(:blob) { fake_blob(path: 'foobar.rb', data: 'puts "hello world"') }
      let(:extra_resource) { { blob: blob } }

      it 'includes the blob name and data in the prompt' do
        expect(agent.prompt[:prompt]).to include("foobar.rb")
        expect(agent.prompt[:prompt]).to include("puts \"hello world\"")
      end
    end
  end
end
