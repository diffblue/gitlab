# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Anthropic::Completions::TanukiBot, feature_category: :duo_chat do
  let_it_be(:user) { create(:user) }

  let(:question) { 'A question' }
  let(:options) { { question: question } }
  let(:params) { { request_id: 'uuid', action: :tanuki_bot } }
  let(:template_class) { ::Gitlab::Llm::Anthropic::Templates::TanukiBot }
  let(:tracking_context) { { request_id: 'uuid', action: :tanuki_bot } }

  let(:ai_response) do
    instance_double(Gitlab::Llm::Anthropic::ResponseModifiers::TanukiBot, response_body: "text", errors: [], extras: {})
  end

  subject(:tanuki_bot) { described_class.new(template_class, params).execute(user, user, options) }

  describe '#execute' do
    let(:tanuki_instance) { instance_double(::Gitlab::Llm::TanukiBot) }

    it 'makes a call to ::Gitlab::Llm::TanukiBot' do
      expect(::Gitlab::Llm::TanukiBot).to receive(:new)
        .with(current_user: user, question: question, tracking_context: tracking_context).and_return(tanuki_instance)
      expect(tanuki_instance).to receive(:execute).and_return(ai_response)

      tanuki_bot
    end

    it 'calls ResponseService' do
      allow(::Gitlab::Llm::TanukiBot).to receive(:new)
        .with(current_user: user, question: question, tracking_context: tracking_context).and_return(tanuki_instance)
      allow(tanuki_instance).to receive(:execute).and_return(ai_response)

      response_modifier = ai_response
      response_service = double
      params = [user, user, response_modifier, { options: { request_id: 'uuid' } }]

      expect(::Gitlab::Llm::GraphqlSubscriptionResponseService).to receive(:new).with(*params).and_return(
        response_service
      )
      expect(response_service).to receive(:execute)

      tanuki_bot
    end

    it 'handles nil responses' do
      allow(::Gitlab::Llm::TanukiBot).to receive(:execute).and_return(
        Gitlab::Llm::ResponseModifiers::EmptyResponseModifier.new(nil)
      )

      expect { tanuki_bot }.not_to raise_error
    end
  end
end
