# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Llm::ResponseService, feature_category: :duo_chat do
  let(:user) { build(:user) }
  let(:issue) { build(:issue) }
  let(:context) do
    Gitlab::Llm::Chain::GitlabContext.new(
      current_user: user, container: nil, resource: issue, ai_request: nil,
      tools_used: []
    )
  end

  let(:basic_options) { { cache_request: true } }
  let(:options) { { cache_request: false } }
  let(:graphql_subscription_double) { instance_double(::Gitlab::Llm::GraphqlSubscriptionResponseService) }

  describe '#execute' do
    it 'calls GraphQL subscription service with the right params' do
      expect(graphql_subscription_double).to receive(:execute)
      expect(::Gitlab::Llm::GraphqlSubscriptionResponseService).to receive(:new)
        .with(user, issue, 'response', options: { cache_request: false }).and_return(graphql_subscription_double)

      described_class.new(context, basic_options).execute(response: 'response', options: options)
    end
  end
end
