# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Llm::GraphqlSubscriptionResponseService, feature_category: :ai_abstraction_layer do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let(:response_body) { 'Some response' }
  let(:cache_response) { false }
  let(:client_subscription_id) { nil }
  let(:ai_action) { nil }

  let(:options) do
    {
      request_id: 'uuid',
      cache_response: cache_response,
      client_subscription_id: client_subscription_id,
      ai_action: ai_action
    }
  end

  let(:ai_response_json) do
    '{
      "id": "cmpl-72baOZiNHv2njeNoWqPZ12xozfPv7",
      "object": "text_completion",
      "created": 1680855492,
      "model": "text-davinci-003",
      "choices": [
        {
          "text": "Some response",
          "index": 0,
          "logprobs": null,
          "finish_reason": "stop"
        }
      ],
      "usage": {
        "prompt_tokens": 8,
        "completion_tokens": 17,
        "total_tokens": 25
      }
    }'
  end

  let(:response_modifier) { Gitlab::Llm::OpenAi::ResponseModifiers::Completions.new(ai_response_json) }

  shared_examples 'graphql subscription response' do
    let(:uuid) { 'u-u-i-d' }
    let(:extras) { { foo: 'bar' } }

    let(:expected_payload) do
      {
        id: uuid,
        content: response_body,
        request_id: 'uuid',
        role: 'assistant',
        timestamp: an_instance_of(ActiveSupport::TimeWithZone),
        errors: [],
        type: nil,
        chunk_id: nil,
        extras: extras
      }
    end

    before do
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
      allow(response_modifier).to receive(:extras).and_return(extras)
    end

    it 'triggers subscription' do
      expect(GraphqlTriggers)
        .to receive(:ai_completion_response)
        .with({ user_id: user.to_global_id, resource_id: expected_resource_gid }, expected_payload)

      subject
    end

    context 'when client_subscription_id is set' do
      let(:client_subscription_id) { 'id' }

      it 'triggers subscription including the client_subscription_id' do
        expect(GraphqlTriggers)
          .to receive(:ai_completion_response)
          .with(
            { user_id: user.to_global_id, resource_id: expected_resource_gid, client_subscription_id: 'id' },
            expected_payload
          )

        subject
      end
    end

    context 'when ai_action is set' do
      let(:ai_action) { 'chat' }

      it 'triggers subscription including the ai_action and removes the resource_id' do
        expect(GraphqlTriggers)
          .to receive(:ai_completion_response)
          .with(
            { user_id: user.to_global_id, ai_action: 'chat' },
            expected_payload
          )

        subject
      end
    end

    context 'when cache_response: true' do
      let(:cache_response) { true }

      it 'caches response' do
        expect_next_instance_of(::Gitlab::Llm::ChatStorage) do |cache|
          expect(cache).to receive(:add)
            .with(expected_payload.slice(:request_id, :errors, :role, :timestamp, :extras, :content))
        end

        subject
      end
    end

    context 'when cache_response: false' do
      let(:cache_response) { false }

      it 'does not cache the response' do
        expect(Gitlab::Llm::ChatStorage).not_to receive(:new)

        subject
      end
    end
  end

  describe '#execute' do
    subject { described_class.new(user, resource, response_modifier, options: options).execute }

    let_it_be(:resource) { create(:merge_request, source_project: project) }

    let(:expected_resource_gid) { resource.to_global_id }

    context 'without user' do
      let(:user) { nil }

      it 'does not broadcast subscription' do
        expect(GraphqlTriggers).not_to receive(:ai_completion_response)

        subject
      end
    end

    context 'for a merge request' do
      it_behaves_like 'graphql subscription response'
    end

    context 'for a work item' do
      let_it_be(:resource) { create(:work_item, project: project) }

      it_behaves_like 'graphql subscription response'
    end

    context 'for an issue' do
      let_it_be(:resource) { create(:issue, project: project) }

      it_behaves_like 'graphql subscription response'
    end

    context 'for an epic' do
      let_it_be(:resource) { create(:epic, group: group) }

      it_behaves_like 'graphql subscription response'
    end

    context 'for internal request' do
      let(:options) { { request_id: 'uuid', internal_request: true, cache_response: cache_response } }

      it 'returns response but does not cache or broadcast' do
        expect(GraphqlTriggers).not_to receive(:ai_completion_response)
        expect(Gitlab::Llm::ChatStorage).not_to receive(:new)

        expect(subject[:content]).to eq(response_body)
      end
    end

    context 'for an empty resource' do
      let_it_be(:resource) { nil }

      let(:expected_resource_gid) { nil }

      it_behaves_like 'graphql subscription response'
    end
  end
end
