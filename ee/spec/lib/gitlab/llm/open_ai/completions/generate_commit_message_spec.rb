# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Completions::GenerateCommitMessage, feature_category: :code_review_workflow do
  let(:prompt_class) { Gitlab::Llm::Templates::GenerateCommitMessage }
  let(:options) { { request_id: 'uuid' } }
  let(:response_modifier) { double }
  let(:response_service) { double }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }
  let(:params) { [user, merge_request, response_modifier, { options: { request_id: 'uuid' } }] }

  subject { described_class.new(prompt_class) }

  before do
    allow(GraphqlTriggers).to receive(:ai_completion_response)
  end

  describe '#execute' do
    context 'when the chat client returns an unsuccessful response' do
      before do
        allow_next_instance_of(Gitlab::Llm::OpenAi::Client) do |client|
          allow(client).to receive(:chat).and_return(
            { error: 'Error' }.to_json
          )
        end
      end

      it 'publishes the error to the graphql subscription' do
        errors = { error: 'Error' }
        expect(::Gitlab::Llm::OpenAi::ResponseModifiers::Chat).to receive(:new).with(errors.to_json).and_return(
          response_modifier
        )
        expect(::Gitlab::Llm::GraphqlSubscriptionResponseService).to receive(:new).with(*params).and_return(
          response_service
        )
        expect(response_service).to receive(:execute)

        subject.execute(user, merge_request, options)
      end
    end

    context 'when the chat client returns a successful response' do
      let(:example_answer) do
        <<-AI.strip
        This is an example AI commit message
        AI
      end

      let(:example_response) do
        {
          'id' => 'chatcmpl-74uDpPnYHVPwLg0RIM6recPqgZKm5',
          'object' => 'chat.completion',
          'created' => 1681403785,
          'model' => 'gpt-3.5-turbo-0301',
          'usage' => {
            'prompt_tokens' => 59,
            'completion_tokens' => 155,
            'total_tokens' => 214
          },
          'choices' => [
            {
              'message' => {
                'role' => 'assistant',
                'content' => example_answer
              },
              'finish_reason' => 'stop',
              'index' => 0
            }
          ]
        }
      end

      before do
        allow_next_instance_of(Gitlab::Llm::OpenAi::Client) do |client|
          allow(client).to receive(:chat).and_return(example_response.to_json)
        end
      end

      it 'publishes the content field from the AI response' do
        expect(::Gitlab::Llm::OpenAi::ResponseModifiers::Chat).to receive(:new).with(example_response.to_json)
          .and_return(response_modifier)
        expect(::Gitlab::Llm::GraphqlSubscriptionResponseService).to receive(:new).with(*params).and_return(
          response_service
        )
        expect(response_service).to receive(:execute)

        subject.execute(user, merge_request, options)
      end

      context 'when an unexpected error is raised' do
        let(:error) { StandardError.new("Error") }

        before do
          allow_next_instance_of(Gitlab::Llm::OpenAi::Client) do |client|
            allow(client).to receive(:chat).and_raise(error)
          end

          allow(Gitlab::ErrorTracking).to receive(:track_exception)
        end

        it 'records the error' do
          subject.execute(user, merge_request, options)

          expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(error)
        end

        it 'publishes a generic error to the graphql subscription' do
          errors = { error: { message: 'An unexpected error has occurred.' } }
          expect(::Gitlab::Llm::OpenAi::ResponseModifiers::Chat).to receive(:new).with(errors.to_json).and_return(
            response_modifier
          )
          expect(::Gitlab::Llm::GraphqlSubscriptionResponseService).to receive(:new).with(*params).and_return(
            response_service
          )
          expect(response_service).to receive(:execute)

          subject.execute(user, merge_request, options)
        end
      end
    end
  end
end
