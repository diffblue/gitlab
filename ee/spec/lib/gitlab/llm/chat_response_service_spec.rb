# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Llm::ChatResponseService, feature_category: :duo_chat do
  let(:user) { create(:user) }
  let(:issue) { create(:issue) }
  let(:context) do
    Gitlab::Llm::Chain::GitlabContext.new(
      current_user: user, container: nil, resource: issue, ai_request: nil,
      tools_used: []
    )
  end

  let(:basic_options) { { cache_request: true, client_subscription_id: 'someid', request_id: 'uuid' } }
  let(:options) { { cache_request: true } }
  let(:graphql_subscription_double) { instance_double(::Gitlab::Llm::GraphqlSubscriptionResponseService) }
  let(:response_double) do
    instance_double(::Gitlab::Llm::Chain::ResponseModifier, response_body: 'response', errors: [], extras: [])
  end

  let(:expected_payload) do
    {
      id: an_instance_of(String),
      request_id: 'uuid',
      content: 'response',
      role: 'assistant',
      timestamp: an_instance_of(ActiveSupport::TimeWithZone),
      errors: [],
      type: nil,
      chunk_id: nil,
      extras: []
    }
  end

  describe '#execute' do
    it 'triggers graphql response with the right params' do
      allow(SecureRandom).to receive(:uuid).and_return('uuid')

      expect(GraphqlTriggers)
        .to receive(:ai_completion_response)
        .with({ user_id: user.to_global_id, ai_action: 'chat' }, expected_payload)

      described_class.new(context, basic_options).execute(response: response_double, options: options)
    end
  end
end
