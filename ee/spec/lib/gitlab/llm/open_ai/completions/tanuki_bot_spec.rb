# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Completions::TanukiBot, feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  let(:question) { 'A question' }
  let(:options) { { question: question, request_id: 'uuid' } }
  let(:template_class) { ::Gitlab::Llm::OpenAi::Templates::TanukiBot }

  let(:ai_response) do
    {
      choices: [
        {
          text: "some ai response text ATTRS: CNT-IDX-123"
        }
      ]
    }.to_json
  end

  subject(:tanuki_bot) { described_class.new(template_class).execute(user, user, options) }

  describe '#execute' do
    it 'makes a call to ::Gitlab::Llm::TanukiBot' do
      expect(::Gitlab::Llm::TanukiBot).to receive(:execute)
        .with(current_user: user, question: question).and_return(ai_response)

      tanuki_bot
    end

    it 'calls ResponseService' do
      allow(::Gitlab::Llm::TanukiBot).to receive(:execute)
        .with(current_user: user, question: question).and_return(ai_response)

      response_modifier = double
      response_service = double
      params = [user, user, response_modifier, { options: { request_id: 'uuid' } }]

      expect(Gitlab::Llm::OpenAi::ResponseModifiers::TanukiBot).to receive(:new).with(ai_response).and_return(
        response_modifier
      )

      expect(::Gitlab::Llm::GraphqlSubscriptionResponseService).to receive(:new).with(*params).and_return(
        response_service
      )
      expect(response_service).to receive(:execute)

      tanuki_bot
    end

    it 'handles nil responses' do
      allow(::Gitlab::Llm::TanukiBot).to receive(:execute).and_return(nil)

      expect { tanuki_bot }.not_to raise_error
    end
  end
end
